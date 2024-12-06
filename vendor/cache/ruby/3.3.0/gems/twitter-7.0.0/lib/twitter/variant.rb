require 'twitter/base'

module Twitter
  class Variant < Twitter::Base
    # @return [Integer]
    attr_reader :bitrate

    # @return [String]
    attr_reader :content_type
    uri_attr_reader :uri
  end
end
