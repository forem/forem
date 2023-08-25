module FeedEvents
  # Inserts a collection of feed events into the database.
  # If an event exists that was created within the timebox provided, the created
  # feed event will have its `counts_for` points set to zero to combat inflating
  # metrics (whether by accident or deliberately).
  class BulkUpsert
    ATTRIBUTES_FOR_INSERT = %i[article_id user_id article_position category context_type].freeze

    def self.call(...)
      new(...).call
    end

    # @param feed_events_data [Array<Hash>] A list of feed events attributes to upsert
    # @param timebox [ActiveSupport] A time window (in minutes) within which feed events must be unique
    def initialize(feed_events_data, timebox: 5.minutes)
      @feed_events_data = feed_events_data
      @timebox = timebox
    end

    def call
      return if valid_events.blank?

      # It's *possible* to construct a single SQL query that does what we
      # want here, but it is more complicated than it sounds.
      # For example, using Postgres' upserting feature (`ON CONFLICT DO...`) is not
      # an option because we *don't* actually want the records to be unique in general,
      # so that constraint does not exist to trigger a conflict.
      # Note that making two queries like this does potentially allow duplicates
      # through a race condition, but that's an acceptable margin of error.
      find_existing_events_within_timebox.each { |event| track_recent_event(event) }

      FeedEvent.insert_all(records_to_insert)
    end

    private

    attr_reader :feed_events_data, :timebox

    def valid_events
      @valid_events ||= feed_events_data.filter_map do |event_data|
        event = FeedEvent.new(event_data)
        event if event.valid?
      end
    end

    def recent_events
      @recent_events ||= Hash.new do |users, user_id|
        users[user_id] = Hash.new do |articles, article_id|
          articles[article_id] = {}
        end
      end
    end

    def recent_event?(event)
      recent_events[event.user_id][event.article_id][event.category].present?
    end

    def track_recent_event(event)
      recent_events[event.user_id][event.article_id][event.category] = true
    end

    def find_existing_events_within_timebox
      values = valid_events.reduce([]) do |acc, event|
        # Postgres is...iffy about comparing NULL (NULL !== NULL), and chokes if it is present in a tuple comparison.
        # Coalescing to 0 is fine because primary keys auto-increment from 1.
        acc << (event.user_id || 0)
        acc << event.article_id
        acc << FeedEvent.categories[event[:category]]
      end

      values_clause = Array.new(valid_events.length) { "(?, ?, ?)" }.join(", ")

      FeedEvent
        .where("created_at > (now() - interval ?)", "#{timebox.in_minutes.to_i} min")
        .where(
          "(COALESCE(user_id, 0), article_id, category) IN (VALUES #{values_clause})",
          *values,
        )
    end

    def records_to_insert
      valid_events.map do |event|
        record = ATTRIBUTES_FOR_INSERT.index_with { |attr| event[attr] }
        record[:counts_for] = recent_event?(event) ? 0 : 1
        track_recent_event(event)

        record
      end
    end
  end
end
