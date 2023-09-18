module Api
  module V1
    class UserRolesController < ApiController
      before_action :authenticate_with_api_key!

      # 'suspended' is also known as 'suspend' for historical reasons
      SUSPEND_MODE = %w{suspend suspended}.freeze
      ROLES = (SUSPEND_MODE + %w{limited}).freeze

      before_action :check_role
      before_action :set_target_user
      before_action :authorize_role_management

      rescue_from StandardError, with: :unprocessable_error

      def update
        if suspend_mode?
          suspend_target_user
        else
          add_role_to_target_user
        end

        render json: { success: "okay" }, status: :no_content
      end

      def destroy
      end

      private
      def add_role_to_target_user
      end

      def authorize_role_management
        authorize(@target_user, :manage_user_roles?)
      end

      def check_role
        unless ROLES.include?(params[:role])
          raise StandardError.new("Unable to process #{params[:role]}")
        end
      end

      def set_target_user
        @target_user = User.find(params[:id])
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
