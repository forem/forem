module Rpush
  module Client
    module ActiveModel
      module Adm
        module Notification
          def self.included(base)
            base.instance_eval do
              validates :registration_ids, presence: true

              validates_with Rpush::Client::ActiveModel::PayloadDataSizeValidator, limit: 6144
              validates_with Rpush::Client::ActiveModel::RegistrationIdsCountValidator, limit: 100

              validates_with Rpush::Client::ActiveModel::Adm::DataValidator
            end
          end

          def as_json(options = nil)
            json = { 'data' => data }
            json['consolidationKey'] = collapse_key if collapse_key
            # number of seconds before message is expired
            json['expiresAfter'] = expiry if expiry
            json
          end
        end
      end
    end
  end
end
