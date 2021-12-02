module Ahoy
  #  @note When we destroy the related user, it's using dependent:
  #        :delete for the relationship.  That means no before/after
  #        destroy callbacks will be called on this object.
  class Event < ApplicationRecord
    include Ahoy::QueryMethods

    self.table_name = "ahoy_events"

    belongs_to :visit
    belongs_to :user, optional: true

    scope :overview_link_clicks, -> { where(name: "Admin Overview Link Clicked") }
  end
end
