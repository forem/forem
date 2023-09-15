module FeedEvents
  # Inserts a collection of feed events into the database.
  #
  # If there are duplicate events in the collection (i.e. having the same user,
  # article, and category) only one will be inserted.
  #
  # If a timebox is provided and there is a duplicate event (using the criteria
  # for uniqueness above) that was created within it, any matching new event will
  # not be created.
  #
  # This avoids inflating metrics (whether by accident or deliberately).
  class BulkUpsert
    ATTRIBUTES_FOR_INSERT = %i[article_id user_id article_position category context_type].freeze

    def self.call(...)
      new(...).call
    end

    # @param feed_events_data [Array<Hash|FeedEvent>] A list of feed events attributes to upsert
    # @param timebox [ActiveSupport::Duration] A time window (in minutes) within which feed events must be unique
    def initialize(feed_events_data, timebox: FeedEvent::DEFAULT_TIMEBOX)
      @feed_events_data = feed_events_data
      @timebox = timebox
    end

    def call
      return if valid_events.blank?

      if valid_events.size == 1
        create_single_event!
        return
      end

      # It's *possible* to construct a single SQL query that does what we want
      # here, (i.e. find existing records, filter out duplicates, and insert the
      # resulting set) but it is more complicated than it sounds.
      # For instance, using Postgres' upserting feature (`ON CONFLICT DO...`) is
      # not an option because we *don't* actually want the records to be unique
      # in general, just within the provided timebox, so there is no constraint
      # to trigger a conflict.
      # Instead we take a Rails-ish `find_or_create_by` approach: first try to
      # find matching record(s), then figure out which new record(s) to insert
      # application-side. Making two queries does potentially allow duplicates
      # (through race conditions), but that's an acceptable margin of error and
      # would be the case anyway with a single query (without locking the table)
      if timebox.present?
        find_existing_events_within_timebox do |event|
          track_recent_event(event)
        end
      end

      records_to_insert = valid_events.filter_map do |event|
        unless recent_event?(event)
          track_recent_event(event)
          ATTRIBUTES_FOR_INSERT.index_with { |attr| event[attr] }
        end
      end

      return if records_to_insert.blank?

      FeedEvent.insert_all(records_to_insert)
      FeedEvent.bulk_update_counters_by_article_id(records_to_insert.pluck(:article_id).sample(5))
    end

    private

    attr_reader :feed_events_data, :timebox

    def valid_events
      @valid_events ||= feed_events_data.filter_map do |event_data|
        event = FeedEvent.new(event_data)
        event if event.valid?
      rescue ArgumentError
        # Enums raise ArgumentError if assigned with invalid value
      end
    end

    def create_single_event!
      event = valid_events.first
      FeedEvent
        .where.not("created_at > ?", timebox.ago.utc) # Only proceed if
        .create_with(event.slice(:article_position, :context_type))
        .find_or_create_by(event.slice(:article_id, :user_id, :category))
    end

    def recent_events
      @recent_events ||= Hash.new do |users, user_id|
        users[user_id] = Hash.new do |categories, category|
          categories[category] = {} # articles
        end
      end
    end

    def recent_event?(event)
      recent_events[event.user_id][event.category][event.article_id]
    end

    def track_recent_event(event)
      recent_events[event.user_id][event.category][event.article_id] = true
    end

    def find_existing_events_within_timebox(&block)
      values = valid_events.reduce([]) do |acc, event|
        acc << event.article_id
        # Postgres is...iffy about comparing NULL (NULL !== NULL), and chokes if it is present in a tuple comparison.
        # Coalescing to 0 is fine because primary keys auto-increment from 1.
        acc << (event.user_id || 0)
        acc << FeedEvent.categories[event[:category]]
      end

      values_clause = Array.new(valid_events.length) { "(?, ?, ?)" }.join(", ")

      FeedEvent
        .where("created_at > ?", timebox.ago.utc)
        .where(
          "(article_id, COALESCE(user_id, 0), category) IN (#{values_clause})",
          *values,
        )
        .each(&block)
    end
  end
end
