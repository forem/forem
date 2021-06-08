module Admin
  module Settings
    class BaseController < Admin::ApplicationController
      MISMATCH_ERROR = "The confirmation key does not match".freeze

      before_action :extra_authorization_and_confirmation, only: [:create]

      def create
        result = upsert_config(settings_params)

        if result.success?
          Audit::Logger.log(:internal, current_user, params.dup)
          redirect_to admin_config_path, notice: "Successfully updated settings."
        else
          redirect_to admin_config_path, alert: "😭 #{result.errors.to_sentence}"
        end
      end

      private

      def extra_authorization_and_confirmation
        not_authorized unless current_user.has_role?(:super_admin)
        raise_confirmation_mismatch_error unless confirmation_text_valid?
      end

      def confirmation_text_valid?
        params.require(:confirmation) ==
          "My username is @#{current_user.username} and this action is 100% safe and appropriate."
      end

      def raise_confirmation_mismatch_error
        raise ActionController::BadRequest.new, MISMATCH_ERROR
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
    end
  end
end
