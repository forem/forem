module Api
  module Admin
    module UserIdentitiesController
      extend ActiveSupport::Concern

      IDENTITY_RENDER_COLUMNS = %i[id user_id provider uid created_at].freeze
      BULK_IDENTITY_LIMIT = 1_000

      def index
        target = User.select(:id).find(params[:user_id])
        @identities = target.identities.select(IDENTITY_RENDER_COLUMNS).order(created_at: :asc)
      end

      def create
        target = params[:username].present? ? User.find(params[:user_id]) : User.select(:id).find(params[:user_id])
        provider = params.require(:provider)
        uid = params.require(:uid).to_s

        ensure_enabled_provider!(provider)

        already_linked = false
        if params[:username].present?
          ActiveRecord::Base.transaction do
            @identity, already_linked = resolve_identity_for_link(target, provider, uid)
            update_provider_username(target, provider, params[:username])
          end
        else
          @identity, already_linked = resolve_identity_for_link(target, provider, uid)
        end

        if already_linked
          render :create, status: :ok
          return
        end

        audit!(slug: "link_identity",
               data: {
                 "target_user_id" => target.id,
                 "identity_id" => @identity.id,
                 "provider" => provider,
                 "uid" => uid
               })
        render :create, status: :created
      end

      def destroy
        target = User.find(params[:user_id])
        identity = target.identities.select(:id, :provider, :uid).find_by(id: params[:id])
        unless identity
          raise Api::Admin::ApiError.new(
            :identity_not_found, I18n.t("admin_api.errors.identity_not_found"), status: 404
          )
        end

        provider = identity.provider
        uid = identity.uid
        identity_id = identity.id

        identity.delete
        update_provider_username(target, provider, nil)
        target.github_repos.destroy_all if provider.to_sym == :github

        audit!(slug: "unlink_identity",
               data: {
                 "target_user_id" => target.id,
                 "identity_id" => identity_id,
                 "provider" => provider,
                 "uid" => uid
               })
        head :no_content
      end

      # Links a batch of identities in one request (the Core -> DEV reverse-link
      # seed is millions of accounts; one HTTP call per identity would take
      # days against the API rate limits). Every entry gets a per-item result
      # - created / already_linked / conflict / not_found / invalid - so one
      # bad row never fails the batch, and the whole batch is audited once.
      def bulk_create
        provider = params.require(:provider)
        ensure_enabled_provider!(provider)

        entries = bulk_entries!
        preload = bulk_preload(provider, entries)
        @results = entries.map { |entry| bulk_link_result(provider, entry, preload) }

        audit!(slug: "bulk_link_identities",
               data: {
                 "provider" => provider,
                 "count" => entries.size,
                 "statuses" => @results.pluck("status").tally
               })
        render :bulk_create, status: :ok
      end

      private

      def ensure_enabled_provider!(provider)
        return if Authentication::Providers.enabled?(provider)

        raise Api::Admin::ApiError.new(:unknown_provider,
                                       I18n.t("admin_api.errors.unknown_provider", provider: provider),
                                       status: 422)
      end

      def bulk_entries!
        entries = params[:identities]
        return entries if entries.is_a?(Array) && entries.size.between?(1, BULK_IDENTITY_LIMIT)

        raise Api::Admin::ApiError.new(
          :invalid_identities,
          I18n.t("admin_api.errors.invalid_identities", limit: BULK_IDENTITY_LIMIT),
          status: 422,
        )
      end

      # Three queries for the whole batch instead of three per row — at 1,000
      # rows per request and ~2M links total, per-row lookups would hammer
      # the DB. Both preloaded indexes are mutated as rows link so same-batch
      # duplicates (by uid or by user) resolve like pre-existing ones; the
      # RecordNotUnique rescue still covers races with concurrent writers.
      def bulk_preload(provider, entries)
        objects = entries.select { |entry| bulk_entry_object?(entry) }
        user_ids = objects.filter_map { |entry| entry[:user_id].presence }
        uids = objects.filter_map { |entry| entry[:uid].presence&.to_s }
        {
          user_ids: User.where(id: user_ids).ids.to_set,
          identities_by_user: Identity.where(provider: provider, user_id: user_ids)
            .select(:id, :user_id, :uid)
            .index_by(&:user_id),
          taken_uids: Identity.where(provider: provider, uid: uids).pluck(:uid).to_set
        }
      end

      # Strings also respond to #[], so require an actual object entry.
      def bulk_entry_object?(entry)
        entry.is_a?(ActionController::Parameters) || entry.is_a?(Hash)
      end

      def bulk_link_result(provider, entry, preload)
        return { "user_id" => nil, "status" => "invalid" } unless bulk_entry_object?(entry)

        user_id = entry[:user_id]
        uid = entry[:uid].to_s
        return { "user_id" => user_id, "status" => "invalid" } if user_id.blank? || uid.blank?

        resolved_user_id = user_id.to_i
        return { "user_id" => resolved_user_id, "status" => "not_found" } unless
          preload[:user_ids].include?(resolved_user_id)

        link_preloaded_identity(provider, resolved_user_id, uid, preload)
      end

      def link_preloaded_identity(provider, user_id, uid, preload)
        existing = preload[:identities_by_user][user_id]
        if existing
          return { "user_id" => user_id, "identity_id" => existing.id, "status" => "already_linked" } if
            existing.uid == uid

          return { "user_id" => user_id, "status" => "conflict",
                   "error_code" => "user_already_has_identity_for_provider" }
        end

        if preload[:taken_uids].include?(uid)
          return { "user_id" => user_id, "status" => "conflict", "error_code" => "identity_uid_taken" }
        end

        identity = insert_verified_identity!(user_id: user_id, provider: provider, uid: uid)
        preload[:taken_uids] << uid
        preload[:identities_by_user][user_id] = identity
        { "user_id" => user_id, "identity_id" => identity.id, "status" => "created" }
      rescue ActiveRecord::RecordNotUnique
        { "user_id" => user_id, "status" => "conflict", "error_code" => "identity_uid_taken" }
      end

      # Returns [identity, already_linked]. Raises Api::Admin::ApiError for the
      # strict-fail-closed conflict states (user has different uid for provider,
      # or uid already linked to another user). Catches RecordNotUnique from
      # the insert to handle the race window between the exists? pre-check
      # and the insert.
      def resolve_identity_for_link(target, provider, uid)
        existing_for_user = target.identities.select(IDENTITY_RENDER_COLUMNS).find_by(provider: provider)
        if existing_for_user
          return [existing_for_user, true] if existing_for_user.uid == uid

          raise Api::Admin::ApiError.new(
            :user_already_has_identity_for_provider,
            I18n.t("admin_api.errors.user_already_has_identity_for_provider", provider: provider),
            status: 409,
          )
        end

        if Identity.exists?(provider: provider, uid: uid)
          raise Api::Admin::ApiError.new(
            :identity_uid_taken,
            I18n.t("admin_api.errors.identity_uid_taken", uid: uid, provider: provider),
            status: 409,
          )
        end

        [insert_verified_identity!(user_id: target.id, provider: provider, uid: uid), false]
      rescue ActiveRecord::RecordNotUnique
        raise Api::Admin::ApiError.new(
          :identity_uid_taken,
          I18n.t("admin_api.errors.identity_uid_taken", uid: uid, provider: provider),
          status: 409,
        )
      end

      # Skips ActiveRecord uniqueness queries on (provider, uid) and
      # (provider, user_id) because callers have already checked both and
      # unique DB indexes + rescue RecordNotUnique enforce them atomically.
      def insert_verified_identity!(user_id:, provider:, uid:)
        identity = Identity.new(user_id: user_id, provider: provider, uid: uid)
        if uid.blank?
          identity.validate
          raise ActiveRecord::RecordInvalid, identity
        end

        identity.save!(validate: false)
        identity
      end

      # Uses `update` (not `update_column`) so the User model's
      # `before_validation clean_provider_username` and uniqueness check on
      # `<provider>_username` run, matching the existing admin UI's
      # `remove_identity` action. Short-circuits when the normalized value is
      # unchanged to avoid a no-op User save, role validations, and Algolia sync.
      def update_provider_username(user, provider, username)
        field = "#{provider}_username"
        return unless user.respond_to?(:"#{field}=")

        cleaned_username = username.presence
        return if user.public_send(field) == cleaned_username
        return if user.update(field => cleaned_username)

        raise ActiveRecord::RecordInvalid, user
      end
    end
  end
end
