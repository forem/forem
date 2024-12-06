module Rpush
  module Client
    module ActiveModel
      module Apns2
        module App
          def self.included(base)
            base.instance_eval do
              validates :environment, presence: true, inclusion: { in: %w(development production sandbox) }
              validates :certificate, presence: true
              validates_with Rpush::Client::ActiveModel::CertificatePrivateKeyValidator
            end
          end

          def service_name
            'apns2'
          end
        end
      end
    end
  end
end
