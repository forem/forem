require 'addressable/uri'

module MetaInspector
  class URL
    attr_reader :url

    def initialize(initial_url, options = {})
      options        = self.class.defaults.merge(options)

      @normalize     = options[:normalize]

      self.url = initial_url
    end

    def scheme
      parsed(url) ? parsed(url).scheme : nil
    end

    def host
      parsed(url) ? parsed(url).host : nil
    end

    def root_url
      "#{scheme}://#{host}/"
    end

    WELL_KNOWN_TRACKING_PARAMS = %w( utm_source utm_medium utm_term utm_content utm_campaign )

    def tracked?
      u = parsed(url)
      return false unless u.query_values
      found_tracking_params = WELL_KNOWN_TRACKING_PARAMS & u.query_values.keys
      return found_tracking_params.any?
    end

    def untracked_url
      u = parsed(url)
      return url unless u.query_values
      query_values = u.query_values.delete_if { |key, _| WELL_KNOWN_TRACKING_PARAMS.include? key }
      u.query_values = query_values.length > 0 ? query_values : nil
      u.to_s
    end

    def untrack!
      self.url = untracked_url if tracked?
    end

    def url=(new_url)
      url  = with_default_scheme(new_url)
      @url = @normalize ? normalized(url) : url
    end

    # Converts a relative URL to an absolute URL, like:
    #   "/faq" => "http://example.com/faq"
    # Respecting already absolute URLs like the ones starting with
    #   http:, ftp:, telnet:, mailto:, javascript: ...
    # Protocol-relative URLs are also resolved to use the same
    # schema as the base_url
    def self.absolutify(url, base_url, options = {})
      options = defaults.merge(options)
      if url =~ /^\w*\:/i
        MetaInspector::URL.new(url, options).url
      else
        uri = Addressable::URI.join(base_url, url)
        options[:normalize] ? uri.normalize.to_s : uri.to_s
      end
    rescue MetaInspector::ParserError, Addressable::URI::InvalidURIError, ArgumentError
      nil
    end

    private

    def self.defaults
      { :normalize => true }
    end

    # Adds 'http' as default scheme, if there is none
    def with_default_scheme(url)
      parsed(url) && parsed(url).scheme.nil? ? 'http://' + url : url
    end

    # Normalize url to deal with characters that should be encoded,
    # add trailing slash, convert to downcase...
    def normalized(url)
      Addressable::URI.parse(url).normalize.to_s
    rescue Addressable::URI::InvalidURIError => e
      raise MetaInspector::ParserError.new(e)
    end

    def parsed(url)
      Addressable::URI.parse(url)
    rescue Addressable::URI::InvalidURIError => e
      raise MetaInspector::ParserError.new(e)
    end
  end
end
