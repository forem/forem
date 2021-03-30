module Admin
  class SettingsController < Admin::ApplicationController
    MISMATCH_ERROR = "The confirmation key does not match".freeze

    before_action :extra_authorization_and_confirmation, only: [:create]

    layout "admin"

    def create; end

    def show
      @confirmation_text = confirmation_text
    end

    private

    def extra_authorization_and_confirmation
      not_authorized unless current_user.has_role?(:super_admin)
      raise_confirmation_mismatch_error if params.require(:confirmation) != confirmation_text
    end

    def confirmation_text
      "My username is @#{current_user.username} and this action is 100% safe and appropriate."
    end

    def raise_confirmation_mismatch_error
      raise ActionController::BadRequest.new, MISMATCH_ERROR
    end
  end
end
