class ConfirmationsController < Devise::ConfirmationsController
  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message!(:notice, :confirmed)
      sign_in(resource)

      if resource.creator?
        redirect_to new_admin_creator_setting_path
      else
        respond_with_navigational(resource) { redirect_to after_confirmation_path_for(resource_name, resource) }
      end
    else
      respond_with_navigational(resource.errors, status: :unprocessable_entity) { render :new }
    end
  end

  def create
    self.resource = resource_class.send_confirmation_instructions(resource_params)
    resource.errors.clear # Don't leak user information, like paranoid mode.

    message = I18n.t("confirmations_controller.email_sent", email: ForemInstance.contact_email)
    flash.now[:global_notice] = message
    render :new
  end
end
