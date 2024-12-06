module Rpush
  module Client
    module ActiveModel
      module Apns2
        include Rpush::Client::ActiveModel::Apns

        module Notification
          MAX_PAYLOAD_BYTESIZE = 4096

          module ClassMethods
            def max_payload_bytesize
              MAX_PAYLOAD_BYTESIZE
            end
          end

          def self.included(base)
            base.extend ClassMethods
          end
        end
      end
    end
  end
end
