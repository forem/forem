module Feeds
  class ResolveAuthor
    def self.call(item, feed_source)
      new(item, feed_source).call
    end

    def initialize(item, feed_source)
      @item = item
      @feed_source = feed_source
    end

    def call
      find_by_email || find_by_name || feed_source.effective_author
    end

    private

    attr_reader :item, :feed_source

    def author_string
      @author_string ||= item.try(:author)&.strip
    end

    def find_by_email
      return unless author_string.present?

      # Extract email from formats like "Name <email@example.com>" or plain "email@example.com"
      email = author_string[/[\w.+-]+@[\w.-]+\.\w+/]
      return unless email

      User.find_by(email: email)
    end

    def find_by_name
      return unless author_string.present?

      # Strip email if present (e.g., "John Doe <john@example.com>" → "John Doe")
      name = author_string.sub(/<[^>]+>/, "").strip
      return if name.blank?

      User.find_by(name: name)
    end
  end
end
