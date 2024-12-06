module Rpush
  module Client
    module ActiveModel
      module Pushy
        module Notification
          def self.included(base)
            base.instance_eval do
              alias_attribute :time_to_live, :expiry

              validates :time_to_live, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
              validates :registration_ids, presence: true
              validates :data, presence: true

              validates_with Rpush::Client::ActiveModel::Pushy::TimeToLiveValidator
              validates_with Rpush::Client::ActiveModel::PayloadDataSizeValidator, limit: 4096
              validates_with Rpush::Client::ActiveModel::RegistrationIdsCountValidator, limit: 1000
            end
          end

          def as_json(_options = nil)
            {
              'data'             => data,
              'time_to_live'     => time_to_live,
              'registration_ids' => registration_ids
            }
          end
        end
      end
    end
  end
end
