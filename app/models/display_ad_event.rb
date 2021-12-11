#  @note When we destroy the related user, it's using dependent:
#        :delete for the relationship.  That means no before/after
#        destroy callbacks will be called on this object.
class DisplayAdEvent < ApplicationRecord
  belongs_to :display_ad
  belongs_to :user

  validates :category, inclusion: { in: %w[impression click] }
  validates :context_type, inclusion: { in: %w[home] }
end
