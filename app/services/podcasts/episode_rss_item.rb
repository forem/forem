# a wrapper/adapter for RSS::Rss::Channel::Item to be able to pass it to ActiveJob
module Podcasts
  class EpisodeRssItem
    ATTRIBUTES = %i[title itunes_subtitle itunes_summary link guid pubDate body enclosure_url].freeze

    attr_reader(*ATTRIBUTES)

    def self.from_item(item)
      new(
        title: item.title,
        itunes_subtitle: item.itunes_subtitle,
        itunes_summary: item.itunes_summary,
        link: item.link,
        guid: item.guid.to_s,
        pubDate: item.pubDate.to_s,
        enclosure_url: item.enclosure&.url,
        body: item.content_encoded || item.itunes_summary || item.description,
      )
    end

    def initialize(attributes)
      ATTRIBUTES.each do |key|
        instance_variable_set("@#{key}", attributes[key])
      end
    end

    def to_h
      ATTRIBUTES.index_with do |key|
        instance_variable_get("@#{key}")
      end
    end
  end
end
