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

      inserted_ids = FeedEvent.transaction(requires_new: true) do
        # Serialize ingestion for each user, including across web processes. Acquire
        # locks in a stable order so overlapping batches cannot deadlock.
        valid_events.pluck(:user_id).uniq.sort_by(&:to_i).each do |user_id|
          key = ForemNative.feed_events_advisory_lock_key(user_id) ||
            Digest::SHA256.digest("feed_events:#{user_id}").unpack1("q>")
          FeedEvent.connection.execute("SELECT pg_advisory_xact_lock(#{key})")
        end
        insert_events!
      end
      return if inserted_ids.blank?

      # Also wait for callers' outer transactions (e.g. digest delivery). Never
      # refresh counters or run model callbacks under ingestion's locks.
      ActiveRecord.after_all_transactions_commit do
        FeedbackWorker.perform_async(inserted_ids)
      rescue StandardError => e
        # Storage already committed. Report the IDs for operational replay rather
        # than return a misleading failure that makes the browser replay storage.
        Rails.error.report(e, context: { worker: FeedbackWorker.name, feed_event_ids: inserted_ids })
      end
    rescue ActiveRecord::InvalidForeignKey
      # Recheck references if an article/user disappeared between lookup and insert.
      # Let a repeated failure propagate so the caller can retry, rather than
      # acknowledging an entire lost batch as successfully recorded.
      attempts = (attempts || 0) + 1
      @recent_events = nil
      @timebox_events = nil
      retry if attempts == 1

      raise
    end

    private

    def unprocessed_events(events)
      event_ids = events.filter_map { |ev| ev[:event_id] }.uniq.sort
      accepted_ids = if event_ids.any?
                       FeedEventReceipt.insert_all(event_ids.map { |id| { id: id } },
                                                   unique_by: :id, returning: %w[id]).pluck("id").to_set
                     else
                       Set.new
                     end
      events.select { |event| event[:event_id].nil? || accepted_ids.delete?(event[:event_id]) }
    end

    def insert_events!
      events = unprocessed_events(records_with_existing_references(valid_events))
      return if events.empty?

      # The user locks cover both the recent-event lookup and insertion.
      # Context is part of the suppression key; event IDs handle delivery retries.
      existing_tuples = []
      if timebox.present?
        @timebox_events = events
        find_existing_events_within_timebox { |tuple| existing_tuples << tuple }
      end

      records_to_insert = deduplicate_events(events, existing_tuples)
      return if records_to_insert.blank?

      persist_records(records_to_insert)
    end

    def records_with_existing_references(records_to_insert)
      article_ids = records_to_insert.filter_map { |r| r[:article_id] }.uniq
      return [] if article_ids.empty?

      valid_article_ids = Set.new(Article.where(id: article_ids).ids)
      user_ids = records_to_insert.filter_map { |r| r[:user_id] }.uniq
      valid_user_ids = user_ids.empty? ? Set.new : Set.new(User.where(id: user_ids).ids)

      records_to_insert.select do |r|
        valid_article_ids.include?(r[:article_id]) &&
          (r[:user_id].nil? || valid_user_ids.include?(r[:user_id]))
      end
    end

    def persist_records(records_to_insert)
      return if records_to_insert.blank?

      FeedEvent.insert_all(records_to_insert, unique_by: :index_feed_events_on_event_id,
                                              returning: %w[id]).pluck("id")
    end

    attr_reader :feed_events_data, :timebox

    def valid_events
      @valid_events ||= ForemNative.validate_and_normalize_feed_events(feed_events_data) ||
        legacy_valid_events
    end

    def legacy_valid_events(events_data = feed_events_data)
      events_data.filter_map do |event_data|
        event = FeedEvent.new(event_data)
        event if event.valid?
      rescue ArgumentError
        # Enums raise ArgumentError if assigned with invalid value
      end
    end

    def deduplicate_events(events, existing_tuples)
      ForemNative.deduplicate_feed_events(events, existing_tuples) ||
        legacy_deduplicate_events(events, existing_tuples)
    end

    def legacy_deduplicate_events(events, existing_tuples)
      existing_tuples.each do |tuple|
        if tuple.is_a?(Array)
          user_id, category, article_id, context_type, feed_config_id = tuple
          recent_events[user_id][category][[article_id, context_type, feed_config_id]] = true
        else
          track_recent_event(tuple)
        end
      end

      events.filter_map do |event|
        unless recent_event?(event)
          track_recent_event(event)
          event.is_a?(Hash) ? event : ATTRIBUTES_FOR_INSERT.index_with { |attr| event[attr] }
        end
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
      recent_events[event[:user_id]][event[:category]][
        [event[:article_id], event[:context_type], event[:feed_config_id]]
      ]
    end

    def track_recent_event(event)
      recent_events[event[:user_id]][event[:category]][
        [event[:article_id], event[:context_type], event[:feed_config_id]]
      ] = true
    end

    def find_existing_events_within_timebox(&block)
      target_events = @timebox_events || valid_events
      return if target_events.empty?

      relation = FeedEvent.where("created_at > ?", timebox.ago.utc)
      # Security contract: ForemNative.feed_events_timebox_lookup_sql only emits
      # SQL containing integer (i64) IDs and allowlisted category enum codes (u8),
      # returning nil on any non-numeric or unrecognized input so we fall back to
      # parameterized legacy_timebox_where. If this lookup ever needs a text field,
      # pass it as a bind parameter rather than extending the native SQL formatter.
      sql_clause = ForemNative.feed_events_timebox_lookup_sql(target_events)
      relation = if sql_clause
                   relation.where(Arel.sql(sql_clause))
                 else
                   legacy_timebox_where(relation, target_events)
                 end

      relation
        .pluck(:user_id, :category, :article_id, :context_type, :feed_config_id)
        .each(&block)
    end

    def legacy_timebox_where(relation, target_events)
      values = target_events.reduce([]) do |acc, event|
        acc << event[:article_id]
        # Postgres is...iffy about comparing NULL (NULL !== NULL), and chokes if it is present in a tuple comparison.
        # Coalescing to 0 is fine because primary keys auto-increment from 1.
        acc << (event[:user_id] || 0)
        acc << FeedEvent.categories[event[:category]]
      end

      values_clause = Array.new(target_events.length) { "(?, ?, ?)" }.join(", ")

      relation.where(
        "(article_id, COALESCE(user_id, 0), category) IN (#{values_clause})",
        *values,
      )
    end
  end
end
