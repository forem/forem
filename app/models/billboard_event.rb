#  @note When we destroy the related user, it's using dependent:
#        :delete for the relationship.  That means no before/after
#        destroy callbacks will be called on this object.
class BillboardEvent < ApplicationRecord
  belongs_to :billboard, class_name: "Billboard", foreign_key: :display_ad_id, inverse_of: :billboard_events
  belongs_to :user, optional: true
  # We also have an article_id param, but not belongs_to because it is not indexed and not designed to be
  # consistently referenced within the application.

  validate :unique_on_user_if_type_of_conversion_category, on: :create
  validate :only_recent_registrations, on: :create

  self.table_name = "display_ad_events"

  alias_attribute :billboard_id, :display_ad_id

  CATEGORY_IMPRESSION = "impression".freeze
  CATEGORY_CLICK = "click".freeze
  CATEGORY_SIGNUP = "signup".freeze
  CATEGORY_CONVERSION = "conversion".freeze
  VALID_CATEGORIES = [CATEGORY_CLICK, CATEGORY_IMPRESSION, CATEGORY_SIGNUP, CATEGORY_CONVERSION].freeze

  CONTEXT_TYPE_HOME = "home".freeze
  CONTEXT_TYPE_ARTICLE = "article".freeze
  CONTEXT_TYPE_EMAIL = "email".freeze
  VALID_CONTEXT_TYPES = [CONTEXT_TYPE_HOME, CONTEXT_TYPE_ARTICLE, CONTEXT_TYPE_EMAIL].freeze

  validates :category, inclusion: { in: VALID_CATEGORIES }
  validates :context_type, inclusion: { in: VALID_CONTEXT_TYPES }

  scope :impressions, -> { where(category: CATEGORY_IMPRESSION) }
  scope :clicks, -> { where(category: CATEGORY_CLICK) }
  scope :signups, -> { where(category: CATEGORY_SIGNUP) }
  scope :conversions, -> { where(category: CATEGORY_CONVERSION) }
  scope :all_conversion_types, -> { where(category: [CATEGORY_SIGNUP, CATEGORY_CONVERSION]) }

  # Adds visible time to an impression the viewer may write to, unless it was updated within
  # the throttle window. Like ApplicationRecord.with_synchronous_commit_off, this commits without
  # waiting on a WAL flush, but in a single round trip instead of four (BEGIN, SET LOCAL, UPDATE,
  # COMMIT): Postgres runs a multi-statement simple query as one implicit transaction, so the
  # SET LOCAL applies only to this UPDATE's commit. Binds would force the extended protocol,
  # which allows only one statement, so values are sanitized inline instead.
  #
  # @return [Integer] the number of rows updated
  def self.add_impression_seconds(id:, user_id:, now: Time.current, seconds: 10, throttle: 9.seconds)
    event_id = type_for_attribute(:id).cast(id)
    return 0 if event_id.nil?

    sql = sanitize_sql_array([<<~SQL.squish, seconds, now, event_id, CATEGORY_IMPRESSION, user_id, now - throttle])
      SET LOCAL synchronous_commit TO OFF;
      UPDATE #{quoted_table_name}
      SET seconds_visible = seconds_visible + ?, updated_at = ?
      WHERE id = ? AND category = ? AND (user_id IS NULL OR user_id = ?) AND updated_at <= ?
    SQL
    connection.exec_update(sql, "#{name} Add Impression Seconds")
  end

  def unique_on_user_if_type_of_conversion_category
    return unless [CATEGORY_SIGNUP, CATEGORY_CONVERSION].include?(category) && user_id.present?
    return unless self.class.exists?(user_id: user_id, category: category)

    errors.add(:user_id, "has already converted")
  end

  def only_recent_registrations
    return unless category == CATEGORY_SIGNUP && user_id.present?
    return unless user.registered_at < 1.day.ago

    errors.add(:user_id, "is not a recent registration")
  end
end
