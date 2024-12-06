module Rpush
  module Client
    module ActiveModel
      module Adm
        module App
          def self.included(base)
            base.instance_eval do
              validates :client_id, :client_secret, presence: true
            end
          end

          def access_token_expired?
            access_token_expiration.nil? || access_token_expiration < Time.now
          end

          def service_name
            'adm'
          end
        end
      end
    end
  end
end
