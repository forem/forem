module Rpush
  module Client
    module ActiveModel
      module Pushy
        class TimeToLiveValidator < ::ActiveModel::Validator
          def validate(record)
            return if record.time_to_live.blank? || record.time_to_live <= 1.year.seconds
            record.errors.add(:time_to_live, 'The maximum value is 1 year')
          end
        end
      end
    end
  end
end
