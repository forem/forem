module MetaInspector
  module Parsers
    class LinksParser < Base
      delegate [:parsed, :url, :scheme, :host] => :@main_parser

      def links
        self
      end

      # Returns all links found, unprocessed
      def raw
        @raw ||= cleanup(parsed.search('//a/@href')).compact.uniq
      end

      # Returns all links found, unrelavitized and absolutified
      def all
        @all ||= raw.map { |link| URL.absolutify(link, base_url) }.compact.uniq
      end

      # Returns all HTTP links found
      def http
        @http ||= all.select { |link| link =~ /^http(s)?:\/\//i}
      end

      # Returns all non-HTTP links found
      def non_http
        @non_http ||= all.select { |link| link !~ /^http(s)?:\/\//i}
      end

      # Returns all internal HTTP links found
      def internal
        @internal ||= http.select { |link| URL.new(link).host == host }
      end

      # Returns all external HTTP links found
      def external
        @external ||= http.select { |link| URL.new(link).host != host }
      end

      def to_hash
        { 'internal' => internal,
          'external' => external,
          'non_http' => non_http }
      end

      # Returns the base url to absolutify relative links.
      # This can be the one set on a <base> tag,
      # or the url of the document if no <base> tag was found.
      def base_url
        current_base_href = base_href.to_s.strip.empty? ? nil : URL.absolutify(base_href, URL.new(url).root_url)
        current_base_href || url
      end

      # Returns the value of the href attribute on the <base /> tag, if exists
      def base_href
        parsed.search('base').first.attributes['href'].value rescue nil
      end
    end
  end
end
