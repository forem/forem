module DeviseInvitable
  module Inviter
    extend ActiveSupport::Concern

    included do
      extend ClassMethods
      attr_writer :invitation_limit unless respond_to? :invitation_limit
    end

    def invitation_limit
      self[:invitation_limit] || self.class.invitation_limit
    end

    # Return true if this user has invitations left to send
    def has_invitations_left?
      if self.class.invitation_limit.present?
        if invitation_limit
          return invitation_limit > 0
        else
          return self.class.invitation_limit > 0
        end
      else
        return true
      end
    end

    protected

      def decrement_invitation_limit!
        if self.class.invitation_limit.present?
          self.invitation_limit ||= self.class.invitation_limit
          self.update_attribute(:invitation_limit, invitation_limit - 1)
        end
      end

      module ClassMethods
        Devise::Models.config(self, :invitation_limit)
      end
  end
end
