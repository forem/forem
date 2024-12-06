# frozen_string_literal: true

module Feedjira
  module AtomEntryUtilities
    def self.included(mod)
      mod.class_exec do
        element :title, as: :raw_title, with: { type: "html" }
        element :title, as: :raw_title, with: { type: "xhtml" }
        element :title, as: :raw_title, with: { type: "xml" }
        element :title, as: :title, with: { type: "text" }
        element :title, as: :title, with: { type: nil }
        element :title, as: :title_type, value: :type

        element :name, as: :author
        element :content
        element :summary
        element :enclosure, as: :image, value: :href

        element :published
        element :id, as: :entry_id
        element :created, as: :published
        element :issued, as: :published
        element :updated
        element :modified, as: :updated

        elements :category, as: :categories, value: :term

        element :link, as: :url, value: :href, with: {
          type: "text/html",
          rel: "alternate"
        }

        elements :link, as: :links, value: :href
      end
    end

    def title
      @title ||=
        case @raw_title
        when String
          Loofah.fragment(@raw_title).xpath("normalize-space(.)")
        else
          @title
        end
    end

    def url
      @url ||= links.first
    end
  end
end
