#  @note When we destroy the related user, it's using dependent:
#        :delete for the relationship.  That means no before/after
#        destroy callbacks will be called on this object.
class BillboardEvent < ApplicationRecord
  belongs_to :billboard, class_name: "Billboard", foreign_key: :display_ad_id, inverse_of: :billboard_events
  belongs_to :user, optional: true

  self.table_name = "display_ad_events"

  alias_attribute :billboard_id, :display_ad_id

  CATEGORY_IMPRESSION = "impression".freeze
  CATEGORY_CLICK = "click".freeze
  VALID_CATEGORIES = [CATEGORY_CLICK, CATEGORY_IMPRESSION].freeze

  CONTEXT_TYPE_HOME = "home".freeze
  CONTEXT_TYPE_ARTICLE = "article".freeze
  VALID_CONTEXT_TYPES = [CONTEXT_TYPE_HOME, CONTEXT_TYPE_ARTICLE].freeze

  validates :category, inclusion: { in: VALID_CATEGORIES }
  validates :context_type, inclusion: { in: VALID_CONTEXT_TYPES }

  scope :impressions, -> { where(category: CATEGORY_IMPRESSION) }
  scope :clicks, -> { where(category: CATEGORY_CLICK) }
end
