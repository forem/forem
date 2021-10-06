class ConfirmationsController < Devise::ConfirmationsController
  FLASH_MESSAGE = "Email sent! Please contact support at %<email>s if you are "\
                  "having trouble receiving your confirmation instructions.".freeze

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message!(:notice, :confirmed)
      if resource.creator?
        sign_in(resource)
        redirect_to root_path
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

    message = format(FLASH_MESSAGE, email: ForemInstance.email)
    flash.now[:global_notice] = message
    render :new
  end
end
