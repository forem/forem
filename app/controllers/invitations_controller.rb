class InvitationsController < Devise::InvitationsController
  def update
    # Copied from https://github.com/scambra/devise_invitable/blob/master/app/controllers/devise/invitations_controller.rb
    # And edited. This is a common devise pattern, similar to OmniauthCallbacksController.
    raw_invitation_token = update_resource_params[:invitation_token]
    self.resource = accept_resource
    invitation_accepted = resource.errors.empty?

    yield resource if block_given?

    if invitation_accepted
      resource.registered = true
      resource.registered_at = Time.current
      if resource.class.allow_insecure_sign_in_after_accept
        flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
        set_flash_message :notice, flash_message if is_flashing_format?
        resource.after_database_authentication
        sign_in(resource_name, resource)
        redirect_to onboarding_path
      else
        set_flash_message :notice, :updated_not_active if is_flashing_format?
        respond_with resource, location: new_session_path(resource_name)
      end
    else
      resource.invitation_token = raw_invitation_token
      respond_with_navigational(resource) { render :edit }
    end
  end
end
