class ConfirmationsController < Devise::ConfirmationsController
  FLASH_MESSAGE = "Email sent! Please contact support at %<email>s if you are "\
    "having trouble receiving your confirmation instructions.".freeze

  def create
    self.resource = resource_class.send_confirmation_instructions(resource_params)
    resource.errors.clear # Don't leak user information, like paranoid mode.

    message = format(FLASH_MESSAGE, email: ForemInstance.email)
    flash.now[:global_notice] = message
    render :new
  end
end
