module Api
  module V1
    class UserRolesController < ApiController
      before_action :authenticate_with_api_key!

      # 'suspended' is also known as 'suspend' for historical reasons
      SUSPEND_MODE = %w[suspend suspended].freeze
      ROLES = (SUSPEND_MODE + %w[limited spam trusted]).freeze

      before_action :check_role
      before_action :set_target_user
      before_action :authorize_role_management

      rescue_from StandardError, with: :unprocessable_error

      def update
        if suspend_mode? # suspend user requires more data, such as note
          suspend_target_user
        else
          add_role_to_target_user
        end

        render json: { success: "okay" }, status: :no_content # rubocop:disable Rails/UnusedRenderContent - adding this as it's been part of the API for a while
      end

      def destroy
        # This mechanism for removing roles is specific to limited, suspended, spam and trusted.
        # We revert them to "Good standing". We would need a different approach,
        # (possibly a whole different service object) to remove *any* roles
        remove_role_from_target_user

        render json: { success: "okay" }, status: :no_content # rubocop:disable Rails/UnusedRenderContent - adding this as it's been part of the API for a while
      end

      private

      def add_role_to_target_user
        manager = Moderator::ManageActivityAndRoles.new(admin: @user,
                                                        user: @target_user,
                                                        user_params: {})
        manager.handle_user_status(params[:role].titleize, nil)

        payload = { action: "api_user_#{params[:role]}", target_user_id: @target_user.id }
        Audit::Logger.log(:admin_api, @user, payload)
      end

      def authorize_role_management
        authorize(@target_user, :manage_user_roles?)
      rescue Pundit::NotAuthorizedError
        error_unauthorized
      end

      def check_role
        return if ROLES.include?(params[:role])

        raise StandardError, "Unable to process #{params[:role]}"
      end

      def remove_role_from_target_user
        manager = Moderator::ManageActivityAndRoles.new(admin: @user,
                                                        user: @target_user,
                                                        user_params: {})
        manager.handle_user_status("Good standing", nil)

        payload = { action: "api_user_remove_#{params[:role]}", target_user_id: @target_user.id }
        Audit::Logger.log(:admin_api, @user, payload)
      end

      def set_target_user
        @target_user = User.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        error_not_found
      end

      def suspend_mode?
        SUSPEND_MODE.include?(params[:role])
      end

      def suspend_target_user
        suspend_params = { note_for_current_role: params[:note], user_status: "Suspended" }
        Moderator::ManageActivityAndRoles.handle_user_roles(admin: @user,
                                                            user: @target_user,
                                                            user_params: suspend_params)

        payload = { action: "api_user_suspend", target_user_id: @target_user.id }
        Audit::Logger.log(:admin_api, @user, payload)
      end

      def unprocessable_error(exception)
        message = @target_user&.errors_as_sentence || exception.message

        render json: {
          success: false,
          message: message
        }, status: :unprocessable_entity
      end
    end
  end
end
