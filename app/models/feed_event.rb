class FeedEvent < ApplicationRecord
  # These are "optional" mostly so that we can perform bulk inserts without triggering
  # article/user validation.
  # Since there are database-level constraints, it's fine to skip Rails-side association validation before saving.
  belongs_to :article, optional: true
  belongs_to :user, optional: true

  enum category: {
    impression: 0,
    click: 1
  }

  CONTEXT_TYPE_HOME = "home".freeze
  CONTEXT_TYPE_SEARCH = "search".freeze
  CONTEXT_TYPE_TAG = "tag".freeze
  VALID_CONTEXT_TYPES = [
    CONTEXT_TYPE_HOME,
    CONTEXT_TYPE_SEARCH,
    CONTEXT_TYPE_TAG,
  ].freeze

  validates :context_type, inclusion: { in: VALID_CONTEXT_TYPES }, presence: true

  # duration is an `ActiveSupport::Duration` e.g. `5.minutes`
  scope :time_ago, ->(duration) { where("created_at > (now() - interval ?)", "#{duration.in_minutes} min") }

  # @param feed_events_data [Array<Hash|FeedEvent>] A list of feed events to match by article, user and category
  def self.matching(feed_events_data)
    values = feed_events_data.reduce([]) do |acc, event|
      # Postgres is...iffy about comparing NULL (NULL !== NULL), and chokes if it is present in a tuple comparison.
      # Coalescing to 0 is safe because primary keys auto-increment from 1.
      acc << event[:article_id].to_i
      acc << event[:user_id].to_i
      acc << categories[event[:category]]
    end

    values_clause = Array.new(feed_events_data.length) { "(?, ?, ?)" }.join(", ")

    where(
      "(feed_events.article_id, COALESCE(feed_events.user_id, 0), feed_events.category) IN (VALUES #{values_clause})",
      *values,
    )
  end

  # Inserts a collection of feed events into the database.
  # If an event exists that was created within the timebox provided, the created feed event will
  # have its points set to zero. This combats inflating metrics whether by accident or deliberately.
  # @param feed_events_data [Array<Hash>] A list of feed events attributes to upsert
  # @param timebox [ActiveSupport] A time window (in minutes) within which feed events must be unique
  def self.bulk_insert_with_timebox(feed_events_data, timebox: 5.minutes)
    feed_events = feed_events_data&.filter_map do |event_data|
      event = new(event_data)
      event if event.valid?
    end
    return if feed_events.blank?

    # It's *possible* to construct a single SQL query that does what we
    # want here, but it is more complicated than it sounds.
    # For example, using Postgres' upserting feature (`ON CONFLICT DO...`) is not
    # an option because we *don't* actually want the records to be unique in general,
    # so that constraint does not exist to trigger a conflict.
    # Note that making two queries like this does potentially allow duplicates
    # through a race condition, but that's an acceptable margin of error.
    recent_events = Hash.new do |articles, article_id|
      articles[article_id] = Hash.new do |users, user_id|
        users[user_id] = {}
      end
    end
    time_ago(timebox).matching(feed_events).each do |event|
      recent_events[event.article_id][event.user_id][event.category] = true
    end

    insert_all(
      feed_events,
    )
  end
end
