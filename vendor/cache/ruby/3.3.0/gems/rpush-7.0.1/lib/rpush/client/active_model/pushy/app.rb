module Rpush
  module Client
    module ActiveModel
      module Pushy
        module App
          def self.included(base)
            base.instance_eval do
              alias_attribute :api_key, :auth_key
              validates :api_key, presence: true
            end
          end

          def service_name
            'pushy'
          end
        end
      end
    end
  end
end
