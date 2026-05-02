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

        unless Authentication::Providers.available.map(&:to_s).include?(provider)
          raise Api::Admin::ApiError.new(:unknown_provider,
                                         "Provider '#{provider}' is not configured",
                                         status: 422)
        end

        ActiveRecord::Base.transaction do
          existing_for_user = target.identities.find_by(provider: provider)
          if existing_for_user
            if existing_for_user.uid == uid
              @identity = existing_for_user
              update_provider_username(target, provider, params[:username]) if params[:username].present?
              return render :create, status: :ok
            else
              raise Api::Admin::ApiError.new(
                :user_already_has_identity_for_provider,
                "User already has identity for provider '#{provider}'",
                status: 409,
              )
            end
          end

          if Identity.exists?(provider: provider, uid: uid)
            raise Api::Admin::ApiError.new(
              :identity_uid_taken,
              "Identity uid #{uid} (#{provider}) is already linked to another user",
              status: 409,
            )
          end

          @identity = Identity.create!(user: target, provider: provider, uid: uid)
          update_provider_username(target, provider, params[:username]) if params[:username].present?
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

      private

      def update_provider_username(user, provider, username)
        field = "#{provider}_username"
        return unless user.respond_to?("#{field}=")

        user.update_column(field, username)
      end
    end
  end
end
