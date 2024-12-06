module Rpush
  module Client
    module ActiveModel
      module Webpush
        module Notification

          class RegistrationValidator < ::ActiveModel::Validator
            KEYS = %i[ endpoint keys ].freeze
            def validate(record)
              return if record.registration_ids.blank?
              return if record.registration_ids.size > 1
              reg = record.registration_ids.first
              unless reg.is_a?(Hash) &&
                  (KEYS-reg.keys).empty? &&
                  reg[:endpoint].is_a?(String) &&
                  reg[:keys].is_a?(Hash)
                record.errors.add(:base, 'Registration must have :endpoint (String) and :keys (Hash) keys')
              end
            end
          end

          def self.included(base)
            base.instance_eval do
              alias_attribute :time_to_live, :expiry

              validates :registration_ids, presence: true
              validates :data, presence: true
              validates :time_to_live, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

              validates_with Rpush::Client::ActiveModel::PayloadDataSizeValidator, limit: 4096
              validates_with Rpush::Client::ActiveModel::RegistrationIdsCountValidator, limit: 1
              validates_with RegistrationValidator
            end
          end

          def data=(value)
            value = value.stringify_keys if value.respond_to?(:stringify_keys)
            super value
          end

          def subscription
            @subscription ||= registration_ids.first.deep_symbolize_keys
          end

          def message
            data['message'].presence if data
          end

          # https://webpush-wg.github.io/webpush-protocol/#urgency
          def urgency
            data['urgency'].presence if data
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
