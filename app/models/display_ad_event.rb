#  @note When we destroy the related user, it's using dependent:
#        :delete for the relationship.  That means no before/after
#        destroy callbacks will be called on this object.
class DisplayAdEvent < ApplicationRecord
  belongs_to :display_ad
  belongs_to :user

  CATEGORY_IMPRESSION = "impression".freeze
  CATEGORY_CLICK = "click".freeze
  VALID_CATEGORIES = [CATEGORY_CLICK, CATEGORY_IMPRESSION].freeze

  CONTEXT_TYPE_HOME = "home".freeze
  VALID_CONTEXT_TYPES = [CONTEXT_TYPE_HOME].freeze

  validates :category, inclusion: { in: VALID_CATEGORIES }
  validates :context_type, inclusion: { in: VALID_CONTEXT_TYPES }

  scope :impressions, -> { where(category: CATEGORY_IMPRESSION) }
  scope :clicks, -> { where(category: CATEGORY_CLICK) }
end
