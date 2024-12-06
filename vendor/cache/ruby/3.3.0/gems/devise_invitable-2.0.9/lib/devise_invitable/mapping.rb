module DeviseInvitable
  module Mapping
    private

      def default_controllers(options)
        unless options[:module]
          options[:controllers] ||= {}
          options[:controllers][:registrations] ||= 'devise_invitable/registrations'
        end
        super
      end
  end
end
