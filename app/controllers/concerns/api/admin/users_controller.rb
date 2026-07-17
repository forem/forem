module Api
  module Admin
    module UsersController
      extend ActiveSupport::Concern

      DEFAULT_PER_PAGE = 25
      MAX_PER_PAGE = 100
      USER_UPDATE_FIELDS = %i[name username].freeze
      PROFILE_UPDATE_FIELDS = %i[summary location website_url].freeze
      ALLOWED_STATUSES = [
        "Good standing", "Suspended", "Spam", "Warned",
        "Comment Suspended", "Trusted", "Limited"
      ].freeze

      def index
        users = filtered_users
        page = positive_integer(params[:page], default: 1)
        per_page = [positive_integer(params[:per_page], default: DEFAULT_PER_PAGE), MAX_PER_PAGE].min

        total = users.count
        @users = users.includes(:identities, :profile, :roles)
          .order(created_at: :desc)
          .offset((page - 1) * per_page)
          .limit(per_page)
        @page = page
        @per_page = per_page
        @total = total
      end

      def show
        @user_record = User.includes(:identities, :profile, :roles).find(params[:id])
      end

      def update
        @user_record = User.find(params[:id])
        before_user = @user_record.slice(*USER_UPDATE_FIELDS)
        before_profile = (@user_record.profile || @user_record.build_profile).slice(*PROFILE_UPDATE_FIELDS)

        user_attrs    = params.permit(*USER_UPDATE_FIELDS).to_h.symbolize_keys
        profile_attrs = params.permit(*PROFILE_UPDATE_FIELDS).to_h.symbolize_keys

        result = Users::Update.call(@user_record, user: user_attrs, profile: profile_attrs)
        unless result.success?
          apply_profile_errors!(@user_record)
          raise ActiveRecord::RecordInvalid, @user_record
        end

        after_user = @user_record.reload.slice(*USER_UPDATE_FIELDS)
        after_profile = (@user_record.profile || Profile.new).slice(*PROFILE_UPDATE_FIELDS)
        changed = diff_changed(before_user.merge(before_profile), after_user.merge(after_profile))

        audit!(slug: "update_user", data: { "target_user_id" => @user_record.id, "changed" => changed })
      end

      def update_email
        @user_record = User.find(params[:id])
        new_email = params.require(:email).to_s.strip.downcase
        old_email = @user_record.email

        unless URI::MailTo::EMAIL_REGEXP.match?(new_email)
          raise Api::Admin::ApiError.new(:validation_failed, I18n.t("admin_api.errors.email_invalid"), status: 422)
        end
        if User.where.not(id: @user_record.id).exists?(email: new_email)
          raise Api::Admin::ApiError.new(:email_taken, I18n.t("admin_api.errors.email_taken"), status: 409)
        end

        # Mirrors the admin UI's `update_email`: bypasses Devise reconfirmation
        # but explicitly bust the user cache that the after_commit hook would
        # otherwise refresh.
        @user_record.update_columns(email: new_email, unconfirmed_email: nil)
        # ...and the Trackable after_commit, so tell the DEV -> Core sync
        # about the new address explicitly.
        @user_record.track!("user_updated")
        Users::BustCacheWorker.perform_async(@user_record.id)
        audit!(slug: "update_user_email",
               data: { "target_user_id" => @user_record.id, "old_email" => old_email, "new_email" => new_email })
        render json: { id: @user_record.id, email: new_email }
      end

      def update_status
        @user_record = User.find(params[:id])
        status = params.require(:status)
        unless ALLOWED_STATUSES.include?(status)
          raise Api::Admin::ApiError.new(:invalid_status, I18n.t("admin_api.errors.invalid_status"), status: 422)
        end

        old_status = user_moderation_status(@user_record)
        Moderator::ManageActivityAndRoles.handle_user_roles(
          admin: current_user,
          user: @user_record,
          user_params: { user_status: status, note_for_current_role: params[:note].to_s },
        )

        audit!(slug: "update_user_status",
               data: {
                 "target_user_id" => @user_record.id,
                 "old_status" => old_status,
                 "new_status" => status,
                 "note" => params[:note].to_s
               })
        render json: { id: @user_record.id, status: status }
      end

      # Lets MLH Core push consent changes (its dev-newsletter opt-outs) back
      # onto the DEV account's local notification settings, which DEV's own
      # senders (digest, newsletter) key off. Writes through the model so the
      # normal callbacks fire (Mailchimp sync, and the CDP newsletter events
      # once enabled) - the resulting echo event is value-idempotent on the
      # Core side.
      def update_notification_settings
        @user_record = User.find(params[:id])
        # Handle the missing wrapper here rather than via params.require, so
        # the caller gets the admin API error_code instead of a generic
        # ParameterMissing 422.
        wrapper = params[:notification_setting]
        updates = wrapper.respond_to?(:permit) ? wrapper.permit(:email_newsletter) : {}
        if updates.blank?
          raise Api::Admin::ApiError.new(:invalid_notification_settings,
                                         I18n.t("admin_api.errors.invalid_notification_settings"),
                                         status: 422)
        end

        setting = @user_record.notification_setting
        # This endpoint carries MLH Core's OWN consent state (its dev
        # newsletter opt-outs/opt-ins). Emitting the CDP newsletter events
        # here would make Core consume its own push as a user consent
        # change — destroying the layered global-unsubscribe vs
        # list-preference distinction. Model callbacks that aren't CDP
        # emission (Mailchimp sync, base_email_eligible) still run.
        User.skip_trackable_events { setting.update!(updates) }

        audit!(slug: "update_notification_settings",
               data: {
                 "target_user_id" => @user_record.id,
                 "changes" => setting.saved_changes.slice("email_newsletter")
               })
        render json: { id: @user_record.id,
                       notification_setting: { email_newsletter: setting.email_newsletter } }
      end

      def merge
        @user_record = User.find(params[:id])
        delete_id = params.require(:merge_user_id).to_i

        if delete_id == @user_record.id
          raise Api::Admin::ApiError.new(
            :cannot_merge_user_into_itself,
            I18n.t("admin_api.errors.cannot_merge_user_into_itself"),
            status: 409,
          )
        end

        # Surface a missing target as 404 before invoking the merge service
        # so the broad-StandardError rescue below only applies to mid-merge
        # identity conflicts (which Moderator::MergeUser raises as plain
        # StandardError with i18n messages).
        delete_user = User.find(delete_id)

        begin
          Moderator::MergeUser.call(
            admin: current_user, keep_user: @user_record, delete_user_id: delete_user.id,
          )
        rescue ActiveRecord::RecordNotFound
          raise
        rescue StandardError => e
          raise Api::Admin::ApiError.new(
            :merge_identity_conflict,
            I18n.t("admin_api.errors.merge_identity_conflict", reason: e.message),
            status: 409,
          )
        end

        audit!(slug: "merge_users",
               data: { "keep_user_id" => @user_record.id, "deleted_user_id" => delete_id })
      end

      def create
        # NOTE: We can add an inviting user here, e.g. User.invite!(current_user, user_params).
        options = {
          custom_invite_subject: params[:custom_invite_subject],
          custom_invite_message: params[:custom_invite_message],
          custom_invite_footnote: params[:custom_invite_footnote]
        }

        User.invite!(invite_params.merge(registered: false), nil, options)

        head :ok
      end

      private

      def filtered_users
        scope = User.all
        scope = scope.where(email: params[:email]) if params[:email].present?
        scope = scope.where(username: params[:username]) if params[:username].present?
        if params[:identity_provider].present? && params[:identity_uid].present?
          scope = scope.joins(:identities)
            .where(identities: {
                     provider: params[:identity_provider],
                     uid: params[:identity_uid]
                   })
        end
        scope
      end

      def positive_integer(value, default:)
        n = value.to_i
        n.positive? ? n : default
      end

      # Given that we expect creators to use tools (e.g. their existing SSO,
      # Zapier, etc) to post to this endpoint I wanted to keep the param
      # structure as simple and flat as possible, hence slightly more manual
      # param handling.
      #
      # NOTE: username is required for the validations on User to succeed.
      def invite_params
        {
          email: params.require(:email),
          name: params[:name],
          username: params[:email]
        }.compact_blank
      end

      def apply_profile_errors!(user_record)
        profile_errors = user_record.profile&.errors&.messages || {}
        profile_errors.each { |attr, msgs| msgs.each { |m| user_record.errors.add(attr, m) } }
      end

      def diff_changed(before, after)
        before.each_with_object({}) do |(key, before_val), memo|
          after_val = after[key]
          memo[key.to_s] = [before_val, after_val] if before_val != after_val
        end
      end
    end
  end
end
