class FreeInvitationsController < Devise::InvitationsController
  protected

    def authenticate_inviter!
    # everyone can invite
    end

    def current_inviter
      current_admin || current_user
    end

    def after_invite_path_for(resource)
      resource ? super : root_path
    end
end
