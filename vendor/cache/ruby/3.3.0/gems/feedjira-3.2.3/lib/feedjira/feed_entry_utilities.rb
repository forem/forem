# frozen_string_literal: true

module Feedjira
  module FeedEntryUtilities
    include Enumerable

    def published
      @published ||= @updated
    end

    def parse_datetime(string)
      DateTime.parse(string).feed_utils_to_gm_time
    rescue StandardError => e
      Feedjira.logger.debug("Failed to parse date #{string.inspect}")
      Feedjira.logger.debug(e)
      nil
    end

    ##
    # Returns the id of the entry or its url if not id is present, as some
    # formats don't support it
    # rubocop:disable Naming/MemoizedInstanceVariableName
    def id
      @entry_id ||= @url
    end
    # rubocop:enable Naming/MemoizedInstanceVariableName

    ##
    # Writer for published. By default, we keep the "oldest" publish time found.
    def published=(val)
      parsed = parse_datetime(val)
      @published = parsed if parsed && (!@published || parsed < @published)
    end

    ##
    # Writer for updated. By default, we keep the most recent update time found.
    def updated=(val)
      parsed = parse_datetime(val)
      @updated = parsed if parsed && (!@updated || parsed > @updated)
    end

    def sanitize!
      %w[title author summary content image].each do |name|
        if respond_to?(name) && send(name).respond_to?(:sanitize!)
          send(name).send(:sanitize!)
        end
      end
    end

    alias last_modified published

    def each
      @rss_fields ||= instance_variables.map do |ivar|
        ivar.to_s.sub("@", "")
      end.select do |field| # rubocop:disable Style/MultilineBlockChain
        # select callable (public) methods only
        respond_to?(field)
      end

      @rss_fields.each do |field|
        yield(field, instance_variable_get(:"@#{field}"))
      end
    end

    def [](field)
      instance_variable_get(:"@#{field}")
    end

    def []=(field, value)
      instance_variable_set(:"@#{field}", value)
    end
  end
end
