module Admin
  module Settings
    class BaseController < Admin::ApplicationController
      before_action :authorize_super_admin
      after_action :bust_agent_guidance_cache, only: %i[create], if: :agent_guidance_settings?

      def create
        result = upsert_config(settings_params)

        if result.success?
          Audit::Logger.log(:internal, current_user, params.dup)
          render json: { message: I18n.t("core.success_settings") }, status: :ok
        else
          render json: { error: result.errors.to_sentence }, status: :unprocessable_entity
        end
      end

      private

      def agent_guidance_settings?
        authorization_resource.in?([::Settings::Community, ::Settings::General])
      end

      def bust_agent_guidance_cache
        EdgeCache::Bust.call("/llms.txt")
      end

      # Override this method if you need to call a custom class for upserting.
      # Ideally such a class eventually calls out to Settings::Upsert and returns
      # the result of that service.
      def upsert_config(settings)
        ::Settings::Upsert.call(settings, authorization_resource)
      end

      # Override this if you need additional params or need to make other changes,
      # e.g. a different require key.
      def settings_params
        params
          .require(:"settings_#{authorization_resource.name.demodulize.underscore}")
          .permit(*authorization_resource.keys)
      end

      def authorize_super_admin
        raise Pundit::NotAuthorizedError unless current_user.super_admin?
      end
    end
  end
end
