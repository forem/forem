module MetaInspector
  module Parsers
    class HeadLinksParser < Base
      delegate [:parsed, :base_url] => :@main_parser

      KNOWN_FEED_TYPES = %w[
        application/rss+xml application/atom+xml application/json
      ].freeze

      def head_links
        @head_links ||= parsed.css('head link').map do |tag|
          Hash[
            tag.attributes.keys.map do |key|
              keysym = key.to_sym
              val = tag.attributes[key].value
              val = URL.absolutify(val, base_url) if keysym == :href
              [keysym, val]
            end
          ]
        end
      end

      def stylesheets
        @stylesheets ||= head_links.select { |hl| hl[:rel] == 'stylesheet' }
      end

      def canonicals
        @canonicals ||= head_links.select { |hl| hl[:rel] == 'canonical' }
      end

      def feeds
        @feeds ||=
          parsed.search("//link[@rel='alternate']").map do |link|
            next if !KNOWN_FEED_TYPES.include?(link["type"]) || link["href"].to_s.strip == ''

            {
              title: link["title"],
              href: URL.absolutify(link["href"], base_url),
              type: link["type"]
            }
          end.compact
      end
    end
  end
end
