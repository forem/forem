module Rpush
  module Client
    module ActiveModel
      module Apns
        class NotificationPayloadSizeValidator < ::ActiveModel::Validator
          def validate(record)
            limit = record.class.max_payload_bytesize
            return unless record.payload.bytesize > limit
            record.errors.add :base, "APN notification cannot be larger than #{limit} bytes. Try condensing your alert and device attributes."
          end
        end
      end
    end
  end
end
