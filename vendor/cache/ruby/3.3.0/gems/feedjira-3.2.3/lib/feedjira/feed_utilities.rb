# frozen_string_literal: true

module Feedjira
  module FeedUtilities
    UPDATABLE_ATTRIBUTES = %w[title feed_url url last_modified etag].freeze

    attr_writer   :new_entries, :updated, :last_modified
    attr_accessor :etag

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def parse(xml, &block)
        xml = strip_whitespace(xml)
        xml = preprocess(xml) if preprocess_xml
        super xml, &block
      end

      def preprocess(xml)
        # noop
        xml
      end

      def preprocess_xml=(value)
        @preprocess_xml = value
      end

      def preprocess_xml
        @preprocess_xml
      end

      def strip_whitespace(xml)
        if Feedjira.strip_whitespace
          xml.strip
        else
          xml.lstrip
        end
      end
    end

    def last_modified
      @last_modified ||= entries.reject { |e| e.published.nil? }.max_by(&:published)&.published
    end

    def updated?
      @updated || false
    end

    def new_entries
      @new_entries ||= []
    end

    def new_entries?
      !new_entries.empty?
    end

    def update_from_feed(feed)
      self.new_entries += find_new_entries_for(feed)
      entries.unshift(*self.new_entries)

      @updated = false

      UPDATABLE_ATTRIBUTES.each do |name|
        @updated ||= update_attribute(feed, name)
      end
    end

    def update_attribute(feed, name)
      old_value = send(name)
      new_value = feed.send(name)

      if old_value == new_value
        false
      else
        send(:"#{name}=", new_value)
        true
      end
    end

    def sanitize_entries!
      entries.each(&:sanitize!)
    end

    private

    # This implementation is a hack, which is why it's so ugly. It's to get
    # around the fact that not all feeds have a published date. However,
    # they're always ordered with the newest one first. So we go through the
    # entries just parsed and insert each one as a new entry until we get to
    # one that has the same id as the the newest for the feed.
    def find_new_entries_for(feed)
      return feed.entries if entries.empty?

      latest_entry = entries.first
      found_new_entries = []

      feed.entries.each do |entry|
        break unless new_entry?(entry, latest_entry)

        found_new_entries << entry
      end

      found_new_entries
    end

    def new_entry?(entry, latest)
      nil_ids = entry.entry_id.nil? && latest.entry_id.nil?
      new_id = entry.entry_id != latest.entry_id
      new_url = entry.url != latest.url

      (nil_ids || new_id) && new_url
    end
  end
end
