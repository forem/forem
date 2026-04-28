module Feeds
  class ValidateUrl
    def self.call(feed_url)
      new(feed_url).call
    end

    def initialize(feed_url)
      @feed_url = feed_url
    end

    def call
      return false if feed_url.blank?

      xml = HTTParty.get(feed_url,
                         timeout: 20,
                         headers: { "User-Agent" => Feeds::Import::FEED_USER_AGENT }).body
      Feedjira.parse(xml)

      true
    rescue Feedjira::NoParserAvailable
      false
    end

    private

    attr_reader :feed_url
  end
end

##############################################################################################################

class ValidateUrl < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    uri = URI.parse(value)

    unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      record.errors.add(attribute, "must be a valid HTTP or HTTPS URL")
      return
    end

    response = URI.open(
      uri,
      "User-Agent" => "Forem RSS Validator",
      read_timeout: 10,
      open_timeout: 10,
    )

    content = response.read

    RSS::Parser.parse(content, false)
  rescue RSS::InvalidRSSError, RSS::NotWellFormedError
    record.errors.add(attribute, "This is not a valid RSS feed")
  rescue URI::InvalidURIError
    record.errors.add(attribute, "Please use a valid URL")
  rescue OpenURI::HTTPError, SocketError, Timeout::Error
    record.errors.add(attribute, "The site could not be reached")
  end
end

######################################################################