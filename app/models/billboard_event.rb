#  @note When we destroy the related user, it's using dependent:
#        :delete for the relationship.  That means no before/after
#        destroy callbacks will be called on this object.
class BillboardEvent < ApplicationRecord
  belongs_to :billboard, class_name: "Billboard", foreign_key: :display_ad_id, inverse_of: :billboard_events
  belongs_to :user, optional: true
  # We also have an article_id param, but not belongs_to because it is not indexed and not designed to be
  # consistently referenced within the application.

  validate :unique_on_user_if_signup_conversion, on: :create
  validate :only_recent_registrations, on: :create

  self.table_name = "display_ad_events"

  alias_attribute :billboard_id, :display_ad_id

  CATEGORY_IMPRESSION = "impression".freeze
  CATEGORY_CLICK = "click".freeze
  CATEGORY_SIGNUP = "signup".freeze
  VALID_CATEGORIES = [CATEGORY_CLICK, CATEGORY_IMPRESSION, CATEGORY_SIGNUP].freeze

  CONTEXT_TYPE_HOME = "home".freeze
  CONTEXT_TYPE_ARTICLE = "article".freeze
  VALID_CONTEXT_TYPES = [CONTEXT_TYPE_HOME, CONTEXT_TYPE_ARTICLE].freeze

  validates :category, inclusion: { in: VALID_CATEGORIES }
  validates :context_type, inclusion: { in: VALID_CONTEXT_TYPES }

  scope :impressions, -> { where(category: CATEGORY_IMPRESSION) }
  scope :clicks, -> { where(category: CATEGORY_CLICK) }
  scope :signups, -> { where(category: CATEGORY_SIGNUP) }

  def unique_on_user_if_signup_conversion
    return unless category == CATEGORY_SIGNUP && user_id.present?
    return unless self.class.exists?(user_id: user_id, category: CATEGORY_SIGNUP)

    errors.add(:user_id, "has already converted a signup")
  end

  def only_recent_registrations
    return unless category == CATEGORY_SIGNUP && user_id.present?
    return unless user.registered_at < 1.day.ago

    errors.add(:user_id, "is not a recent registration")
  end
end
