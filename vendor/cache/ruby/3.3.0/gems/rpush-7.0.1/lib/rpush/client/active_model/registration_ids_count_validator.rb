module Rpush
  module Client
    module ActiveModel
      class RegistrationIdsCountValidator < ::ActiveModel::Validator
        def validate(record)
          limit = options[:limit] || 100
          return unless record.registration_ids && record.registration_ids.size > limit
          record.errors.add :base, "Number of registration_ids cannot be larger than #{limit}."
        end
      end
    end
  end
end
