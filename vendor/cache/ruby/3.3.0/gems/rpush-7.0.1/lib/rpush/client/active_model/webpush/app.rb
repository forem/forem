module Rpush
  module Client
    module ActiveModel
      module Webpush
        module App

          class VapidKeypairValidator < ::ActiveModel::Validator
            def validate(record)
              return if record.vapid_keypair.blank?
              keypair = record.vapid
              %i[ subject public_key private_key ].each do |key|
                unless keypair.key?(key)
                  record.errors.add(:vapid_keypair, "must have a #{key} entry")
                end
              end
            rescue
              record.errors.add(:vapid_keypair, 'must be valid JSON')
            end
          end

          def self.included(base)
            base.class_eval do
              alias_attribute :vapid_keypair, :certificate
              validates :vapid_keypair, presence: true
              validates_with VapidKeypairValidator
            end
          end

          def service_name
            'webpush'
          end

          def vapid
            @vapid ||= JSON.parse(vapid_keypair).symbolize_keys
          end

        end
      end
    end
  end
end
