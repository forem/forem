module Webhook
  class Endpoint < ApplicationRecord
    belongs_to :user, inverse_of: :webhook_endpoints

    validates :target_url, uniqueness: true, url: { schemes: %w[https] }
    validates :events, presence: true

    attribute :events, :string, array: true, default: []

    scope :for_events, ->(events) { where("events @> ARRAY[?]::varchar[]", Array(events)) }

    def self.table_name_prefix
      "webhook_"
    end
  end
end
