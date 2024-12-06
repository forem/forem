module Rpush
  module Client
    module ActiveModel
      class PayloadDataSizeValidator < ::ActiveModel::Validator
        def validate(record)
          limit = options[:limit] || 1024
          return unless record.data && record.payload_data_size > limit
          record.errors.add :base, "Notification payload data cannot be larger than #{limit} bytes."
        end
      end
    end
  end
end
