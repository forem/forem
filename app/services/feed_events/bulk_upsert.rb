module FeedEvents
  # Inserts a collection of feed events into the database.
  #
  # If there are duplicate events in the collection (i.e. having the same user,
  # article, category, context, and feed configuration) only one will be inserted.
  #
  # If a timebox is provided and there is a duplicate event (using the criteria
  # for uniqueness above) that was created within it, any matching new event will
  # not be created.
  #
  # This avoids inflating metrics (whether by accident or deliberately).
  class BulkUpsert
    ATTRIBUTES_FOR_INSERT = %i[article_id user_id article_position category context_type feed_config_id event_id].freeze

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

      FeedEvent.transaction(requires_new: true) do
        # Serialize ingestion for each user, including across web processes. Acquire
        # locks in a stable order so overlapping batches cannot deadlock.
        valid_events.map(&:user_id).uniq.sort_by(&:to_i).each do |user_id|
          key = Digest::SHA256.digest("feed_events:#{user_id}").unpack1("q>")
          FeedEvent.connection.execute("SELECT pg_advisory_xact_lock(#{key})")
        end
        insert_events!
      end
    rescue ActiveRecord::InvalidForeignKey
      # Recheck references if an article/user disappeared between lookup and insert.
      # Let a repeated failure propagate so the caller can retry, rather than
      # acknowledging an entire lost batch as successfully recorded.
      attempts = (attempts || 0) + 1
      @recent_events = nil
      retry if attempts == 1

      raise
    end

    private

    def unprocessed_events(events)
      event_ids = events.filter_map(&:event_id).uniq.sort
      accepted_ids = if event_ids.any?
                       FeedEventReceipt.insert_all(event_ids.map { |id| { id: id } },
                                                   unique_by: :id, returning: %w[id]).pluck("id").to_set
                     else
                       Set.new
                     end
      events.select { |event| event.event_id.nil? || accepted_ids.delete?(event.event_id) }
    end

    def insert_events!
      events = unprocessed_events(records_with_existing_references(valid_events))
      return if events.empty?

      # The user locks cover both the recent-event lookup and insertion.
      # Context is part of the suppression key; event IDs handle delivery retries.
      if timebox.present?
        find_existing_events_within_timebox do |event|
          track_recent_event(event)
        end
      end

      records_to_insert = events.filter_map do |event|
        unless recent_event?(event)
          track_recent_event(event)
          ATTRIBUTES_FOR_INSERT.index_with { |attr| event[attr] }
        end
      end

      return if records_to_insert.blank?

      persist_records(records_to_insert)
    end

    def records_with_existing_references(records_to_insert)
      article_ids = records_to_insert.pluck(:article_id).compact.uniq
      valid_article_ids = Set.new(Article.where(id: article_ids).ids)
      user_ids = records_to_insert.pluck(:user_id).compact.uniq
      valid_user_ids = Set.new(User.where(id: user_ids).ids)

      records_to_insert.select do |r|
        valid_article_ids.include?(r[:article_id]) &&
          (r[:user_id].nil? || valid_user_ids.include?(r[:user_id]))
      end
    end

    def persist_records(records_to_insert)
      return if records_to_insert.blank?

      if valid_events.one? && records_to_insert.one?
        single_record = records_to_insert.first
        return if single_record[:event_id].present? && FeedEvent.exists?(event_id: single_record[:event_id])

        # Preserve the single-event callbacks used by engagement scoring.
        FeedEvent.create!(single_record)
      else
        impressions, engagements = records_to_insert.partition do |record|
          record[:category] == "impression"
        end
        persist_impressions(impressions)
        # Engagement must run the same scoring/evolution callbacks at every
        # batch size. Insert impressions first so maturity checks see exposure.
        engagements.each { |record| FeedEvent.create!(record) }
      end
    end

    def persist_impressions(records)
      return if records.empty?

      inserted = FeedEvent.insert_all(records, unique_by: :index_feed_events_on_event_id,
                                               returning: %w[article_id feed_config_id]).to_a
      FeedEvent.bulk_update_counters_by_article_id(inserted.pluck("article_id").uniq)
      FeedEvent.bulk_update_counters_by_feed_config_id(inserted.pluck("feed_config_id").compact)
    end

    attr_reader :feed_events_data, :timebox

    def valid_events
      @valid_events ||= feed_events_data.filter_map do |event_data|
        event = FeedEvent.new(event_data)
        event if event.valid?
      rescue ArgumentError
        # Enums raise ArgumentError if assigned with invalid value
      end
    end

    def recent_events
      @recent_events ||= Hash.new do |users, user_id|
        users[user_id] = Hash.new do |categories, category|
          categories[category] = {} # articles
        end
      end
    end

    def recent_event?(event)
      recent_events[event.user_id][event.category][[event.article_id, event.context_type, event.feed_config_id]]
    end

    def track_recent_event(event)
      recent_events[event.user_id][event.category][[event.article_id, event.context_type, event.feed_config_id]] = true
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
        .find_each(&block)
    end
  end
end
