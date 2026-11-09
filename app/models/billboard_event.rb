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
  CONTEXT_TYPE_EMBED = "embed".freeze
  VALID_CONTEXT_TYPES = [CONTEXT_TYPE_HOME, CONTEXT_TYPE_ARTICLE, CONTEXT_TYPE_EMAIL, CONTEXT_TYPE_EMBED].freeze
  FAST_INSERT_KEYS = %w[
    billboard billboard_id display_ad_id category context_type
    user_id article_id geolocation user_agent counts_for seconds_visible
  ].flat_map { |k| [k, k.to_sym] }.to_set.freeze

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
    sql = build_add_impression_seconds_sql(
      id: id, user_id: user_id, now: now, seconds: seconds, throttle: throttle,
    )
    return 0 if sql.nil?

    with_connection_retry { connection.exec_update(sql, "#{name} Add Impression Seconds") }
  end

  def self.build_add_impression_seconds_sql(id:, user_id:, now: Time.current, seconds: 10, throttle: 9.seconds)
    native = ForemNative.billboard_event_update_sql(id, user_id, seconds, now, now - throttle)
    return if native == :invalid
    return native if native

    legacy_add_impression_seconds_sql(
      id: id, user_id: user_id, now: now, seconds: seconds, throttle: throttle,
    )
  end

  def self.legacy_add_impression_seconds_sql(id:, user_id:, now: Time.current, seconds: 10, throttle: 9.seconds)
    event_id = type_for_attribute(:id).cast(id)
    return if event_id.nil?

    sanitize_sql_array([<<~SQL.squish, seconds, now, event_id, CATEGORY_IMPRESSION, user_id, now - throttle])
      SET LOCAL synchronous_commit TO OFF;
      UPDATE #{quoted_table_name}
      SET seconds_visible = seconds_visible + ?, updated_at = ?
      WHERE id = ? AND category = ? AND (user_id IS NULL OR user_id = ?) AND updated_at <= ?
    SQL
  end
  private_class_method :legacy_add_impression_seconds_sql

  # Validates and inserts a new event like create does, committing without waiting on a WAL flush
  # in a single round trip instead of four (BEGIN, SET LOCAL, INSERT, COMMIT), the same way
  # add_impression_seconds does for its UPDATE. Values are serialized by each attribute's type and
  # quoted inline, because binds would force the extended protocol.
  #
  # @return [Integer, nil] the new event's id, or nil when the event is invalid
  def self.create_with_async_commit(attributes, now: Time.current)
    sql = build_create_with_async_commit_sql(attributes, now: now)
    return unless sql

    row = with_connection_retry { connection.exec_query(sql, "#{name} Create") }.rows.first
    type_for_attribute(primary_key).cast(row.first) if row
  end

  def self.with_connection_retry
    retried = false
    begin
      yield
    rescue ActiveRecord::ConnectionFailed
      raise if retried

      retried = true
      connection.reconnect!
      retry
    end
  end
  private_class_method :with_connection_retry

  def self.build_create_with_async_commit_sql(attributes, now: Time.current)
    attrs = attributes.respond_to?(:to_unsafe_h) ? attributes.to_unsafe_h : attributes.to_h
    if now.respond_to?(:tv_sec) && attrs.each_key.all? { |k| FAST_INSERT_KEYS.include?(k) }
      native = native_create_with_async_commit_sql(attrs.symbolize_keys, now)
      return if native == :invalid
      return native if native
    end

    legacy_create_with_async_commit_sql(attributes, now: now)
  end

  def self.native_create_with_async_commit_sql(attrs, now)
    if attrs.key?(:billboard)
      billboard = attrs[:billboard]
      return :invalid if billboard.nil?
      return unless billboard.is_a?(Billboard) && billboard.id

      display_ad_id = billboard.id
      verify_exists = false
    else
      display_ad_id = attrs[:billboard_id] || attrs[:display_ad_id]
      verify_exists = true
    end

    now_utc = now.utc? ? now : now.getutc
    ForemNative.billboard_event_insert_sql(
      [
        display_ad_id, attrs[:category], attrs[:context_type], attrs[:user_id],
        attrs[:article_id], attrs[:geolocation], attrs[:user_agent],
        attrs[:counts_for], attrs[:seconds_visible], now_utc.tv_sec, now_utc.usec, verify_exists
      ],
    )
  end
  private_class_method :native_create_with_async_commit_sql

  def self.legacy_create_with_async_commit_sql(attributes, now: Time.current)
    attrs = attributes.to_h.symbolize_keys
    if !attrs.key?(:billboard) && (attrs.key?(:billboard_id) || attrs.key?(:display_ad_id))
      raw_id = attrs.delete(:billboard_id) || attrs.delete(:display_ad_id)
      cast_id = type_for_attribute(:display_ad_id).cast(raw_id)
      attrs[:billboard] = Billboard.select(:id).find_by(id: cast_id) if cast_id
    end

    event = new(attrs)
    return unless event.valid?

    event.created_at = event.updated_at = now
    values = event.attributes.except(primary_key).sort.to_h
    columns = values.keys.map { |column| connection.quote_column_name(column) }
    quoted_values = values.map { |column, value| connection.quote(type_for_attribute(column).serialize(value)) }
    <<~SQL.squish
      SET LOCAL synchronous_commit TO OFF;
      INSERT INTO #{quoted_table_name} (#{columns.join(', ')}) VALUES (#{quoted_values.join(', ')})
      RETURNING #{connection.quote_column_name(primary_key)}
    SQL
  end
  private_class_method :legacy_create_with_async_commit_sql

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
