class Devise::InvitationsController < DeviseController
  prepend_before_action :authenticate_inviter!, only: [:new, :create]
  prepend_before_action :has_invitations_left?, only: [:create]
  prepend_before_action :require_no_authentication, only: [:edit, :update, :destroy]
  prepend_before_action :resource_from_invitation_token, only: [:edit, :destroy]

  if respond_to? :helper_method
    helper_method :after_sign_in_path_for
  end

  # GET /resource/invitation/new
  def new
    self.resource = resource_class.new
    render :new
  end

  # POST /resource/invitation
  def create
    self.resource = invite_resource
    resource_invited = resource.errors.empty?

    yield resource if block_given?

    if resource_invited
      if is_flashing_format? && self.resource.invitation_sent_at
        set_flash_message :notice, :send_instructions, email: self.resource.email
      end
      if self.method(:after_invite_path_for).arity == 1
        respond_with resource, location: after_invite_path_for(current_inviter)
      else
        respond_with resource, location: after_invite_path_for(current_inviter, resource)
      end
    else
      respond_with(resource)
    end
  end

  # GET /resource/invitation/accept?invitation_token=abcdef
  def edit
    set_minimum_password_length
    resource.invitation_token = params[:invitation_token]
    render :edit
  end

  # PUT /resource/invitation
  def update
    raw_invitation_token = update_resource_params[:invitation_token]
    self.resource = accept_resource
    invitation_accepted = resource.errors.empty?

    yield resource if block_given?

    if invitation_accepted
      if resource.class.allow_insecure_sign_in_after_accept
        flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
        set_flash_message :notice, flash_message if is_flashing_format?
        resource.after_database_authentication
        sign_in(resource_name, resource)
        respond_with resource, location: after_accept_path_for(resource)
      else
        set_flash_message :notice, :updated_not_active if is_flashing_format?
        respond_with resource, location: new_session_path(resource_name)
      end
    else
      resource.invitation_token = raw_invitation_token
      respond_with(resource)
    end
  end

  # GET /resource/invitation/remove?invitation_token=abcdef
  def destroy
    resource.destroy
    set_flash_message :notice, :invitation_removed if is_flashing_format?
    redirect_to after_sign_out_path_for(resource_name)
  end

  protected

    def invite_resource(&block)
      resource_class.invite!(invite_params, current_inviter, &block)
    end

    def accept_resource
      resource_class.accept_invitation!(update_resource_params)
    end

    def current_inviter
      authenticate_inviter!
    end

    def has_invitations_left?
      unless current_inviter.nil? || current_inviter.has_invitations_left?
        self.resource = resource_class.new
        set_flash_message :alert, :no_invitations_remaining if is_flashing_format?
        respond_with_navigational(resource) { render :new }
      end
    end

    def resource_from_invitation_token
      unless params[:invitation_token] && self.resource = resource_class.find_by_invitation_token(params[:invitation_token], true)
        set_flash_message(:alert, :invitation_token_invalid) if is_flashing_format?
        redirect_to invalid_token_path_for(resource_name)
      end
    end

    def invite_params
      devise_parameter_sanitizer.sanitize(:invite)
    end

    def update_resource_params
      devise_parameter_sanitizer.sanitize(:accept_invitation)
    end

    def translation_scope
      'devise.invitations'
    end
end
