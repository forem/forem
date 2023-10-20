module Ahoy
  #  @note When we destroy the related user, it's using dependent:
  #        :delete for the relationship.  That means no before/after
  #        destroy callbacks will be called on this object.
  class Visit < ApplicationRecord
    self.table_name = "ahoy_visits"

    has_many :events, class_name: "Ahoy::Event", dependent: :destroy
    belongs_to :user, optional: true
    belongs_to :user_visit_context, optional: true
  end
end
