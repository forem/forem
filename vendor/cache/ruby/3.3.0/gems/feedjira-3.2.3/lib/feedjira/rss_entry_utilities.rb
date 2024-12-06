# frozen_string_literal: true

module Feedjira
  module RSSEntryUtilities
    # rubocop:todo Metrics/MethodLength
    def self.included(mod) # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
      mod.class_exec do
        element :title

        element :"content:encoded", as: :content
        element :"a10:content", as: :content
        element :description, as: :summary

        element :link, as: :url
        element :"a10:link", as: :url, value: :href

        element :author
        element :"dc:creator", as: :author
        element :"a10:name", as: :author

        element :pubDate, as: :published
        element :pubdate, as: :published
        element :issued, as: :published
        element :"dc:date", as: :published
        element :"dc:Date", as: :published
        element :"dcterms:created", as: :published

        element :"dcterms:modified", as: :updated
        element :"a10:updated", as: :updated

        element :guid, as: :entry_id, class: Feedjira::Parser::GloballyUniqueIdentifier
        element :"dc:identifier", as: :dc_identifier

        element :"media:thumbnail", as: :image, value: :url
        element :"media:content", as: :image, value: :url
        element :enclosure, as: :image, value: :url

        element :comments

        elements :category, as: :categories
      end
    end
    # rubocop:enable Metrics/MethodLength

    def entry_id
      @entry_id&.guid
    end

    def url
      @url || @entry_id&.url
    end

    def id
      entry_id || @dc_identifier || @url
    end
  end
end
