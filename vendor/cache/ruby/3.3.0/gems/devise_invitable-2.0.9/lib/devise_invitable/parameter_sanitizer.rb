module DeviseInvitable
  module ParameterSanitizer
    if defined?(Devise::BaseSanitizer)
      def invite
        permit self.for(:invite)
      end

      def accept_invitation
        permit self.for(:accept_invitation)
      end
    end

    private

      if defined?(Devise::BaseSanitizer)
        def permit(keys)
          default_params.permit(*Array(keys))
        end

        def attributes_for(kind)
          case kind
          when :invite
            resource_class.respond_to?(:invite_key_fields) ? resource_class.invite_key_fields : []
          when :accept_invitation
            [:password, :password_confirmation, :invitation_token]
          else
            super
          end
        end
      else
        def initialize(resource_class, resource_name, params)
          super
          permit(:invite, keys: (resource_class.respond_to?(:invite_key_fields) ? resource_class.invite_key_fields : []) )
          permit(:accept_invitation, keys: [:password, :password_confirmation, :invitation_token] )
        end
      end
  end
end
