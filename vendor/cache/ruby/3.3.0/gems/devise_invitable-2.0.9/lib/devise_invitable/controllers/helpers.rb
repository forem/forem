module DeviseInvitable::Controllers::Helpers
  extend ActiveSupport::Concern

  included do
  end

  def after_invite_path_for(inviter, invitee = nil)
    signed_in_root_path(inviter)
  end

  def after_accept_path_for(resource)
    signed_in_root_path(resource)
  end

  def invalid_token_path_for(resource_name)
    after_sign_out_path_for(resource_name)
  end

  protected

    def authenticate_inviter!
      send(:"authenticate_#{resource_name}!", force: true)
    end
end

