module Rpush
  module Client
    module ActiveModel
      module Apns
        class DeviceTokenFormatValidator < ::ActiveModel::Validator
          def validate(record)
            return if record.device_token =~ /\A[a-z0-9]\w+\z/i
            record.errors.add :device_token, "is invalid"
          end
        end
      end
    end
  end
end
