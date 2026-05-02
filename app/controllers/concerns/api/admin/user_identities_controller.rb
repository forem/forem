module Api
  module Admin
    module UserIdentitiesController
      extend ActiveSupport::Concern

      def index
        target = User.find(params[:user_id])
        @identities = target.identities.order(created_at: :asc)
      end

      def create
        target = User.find(params[:user_id])
        provider = params.require(:provider)
        uid = params.require(:uid).to_s

        unless Authentication::Providers.available?(provider)
          raise Api::Admin::ApiError.new(:unknown_provider,
                                         I18n.t("admin_api.errors.unknown_provider", provider: provider),
                                         status: 422)
        end

        already_linked = false
        ActiveRecord::Base.transaction do
          existing_for_user = target.identities.find_by(provider: provider)
          if existing_for_user
            if existing_for_user.uid == uid
              @identity = existing_for_user
              update_provider_username(target, provider, params[:username]) if params[:username].present?
              already_linked = true
              next
            else
              raise Api::Admin::ApiError.new(
                :user_already_has_identity_for_provider,
                I18n.t("admin_api.errors.user_already_has_identity_for_provider", provider: provider),
                status: 409,
              )
            end
          end

          if Identity.exists?(provider: provider, uid: uid)
            raise Api::Admin::ApiError.new(
              :identity_uid_taken,
              I18n.t("admin_api.errors.identity_uid_taken", uid: uid, provider: provider),
              status: 409,
            )
          end

          @identity = Identity.create!(user: target, provider: provider, uid: uid)
          update_provider_username(target, provider, params[:username]) if params[:username].present?
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
        identity = target.identities.find_by(id: params[:id])
        unless identity
          raise Api::Admin::ApiError.new(
            :identity_not_found, I18n.t("admin_api.errors.identity_not_found"), status: 404
          )
        end

        provider = identity.provider
        uid = identity.uid
        identity_id = identity.id

        identity.destroy!
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

      private

      def update_provider_username(user, provider, username)
        field = "#{provider}_username"
        return unless user.respond_to?(:"#{field}=")

        user.update_column(field, username)
      end
    end
  end
end
