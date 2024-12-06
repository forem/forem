module Rpush
  module Client
    module ActiveModel
      module Apnsp8
        module App
          def self.included(base)
            base.instance_eval do
              validates :environment, presence: true, inclusion: { in: %w(development production sandbox) }
              validates :apn_key, presence: true
              validates :apn_key_id, presence: true
              validates :team_id, presence: true
              validates :bundle_id, presence: true
            end
          end

          def service_name
            'apnsp8'
          end
        end
      end
    end
  end
end
