module Rpush
  module Client
    module ActiveModel
      module Gcm
        class ExpiryCollapseKeyMutualInclusionValidator < ::ActiveModel::Validator
          def validate(record)
            return unless record.collapse_key && !record.expiry
            record.errors.add :expiry, 'must be set when using a collapse_key'
          end
        end
      end
    end
  end
end
