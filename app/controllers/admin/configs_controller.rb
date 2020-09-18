module Admin
  class ConfigsController < Admin::ApplicationController
    layout "admin"

    before_action :extra_authorization_and_confirmation, only: [:create]
    before_action :validate_inputs, only: [:create]

    def show
      @confirmation_text = confirmation_text
    end

    def create
      Admin::Configs::Upsert.call(params)
      redirect_to admin_config_path, notice: "Site configuration was successfully updated."
    end

    private

    def confirmation_text
      "My username is @#{current_user.username} and this action is 100% safe and appropriate."
    end

    def extra_authorization_and_confirmation
      not_authorized unless current_user.has_role?(:single_resource_admin, Config) # Special additional permission
      raise_confirmation_mismatch_error if params.require(:confirmation) != confirmation_text
    end
  end
end
