class DeviseInvitable::RegistrationsController < Devise::RegistrationsController
  protected

    def build_resource(hash = {})
      if hash[:email]
        self.resource = resource_class.where(email: hash[:email]).first
        if self.resource && self.resource.respond_to?(:invited_to_sign_up?) && self.resource.invited_to_sign_up?
          self.resource.attributes = hash
          self.resource.send_confirmation_instructions if self.resource.confirmation_required_for_invited?
          self.resource.accept_invitation
        else
          self.resource = nil
        end
      end
      self.resource ||= super
    end
end
