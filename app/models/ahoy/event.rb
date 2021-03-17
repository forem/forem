module Ahoy
  class Event < ApplicationRecord
    include Ahoy::QueryMethods

    self.table_name = "ahoy_events"

    belongs_to :visit
    belongs_to :user, optional: true

    scope :overview_link_clicks, -> { where(name: "Overview Link Clicked") }
  end
end
