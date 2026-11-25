module Search
  class Tag
    ATTRIBUTES = %i[id name hotness_score rules_html supported short_summary bg_color_hex badge_id].freeze

    DEFAULT_PER_PAGE = 60
    MAX_PER_PAGE = 100

    def self.search_documents(
      page: 0,
      per_page: DEFAULT_PER_PAGE,
      term: nil,
      format: :hash
    )
      results = ::Tag.search_by_name(term).supported.includes(:badge)
        .reorder(hotness_score: :desc).page(page).per(per_page).select(*ATTRIBUTES)

      if format == :json && ForemNative.available?
        json = serialize_json_natively(results)
        return Homepage::ArticleSerializer::EncodedJson.new(json) if json
      end

      serialize(results)
    end

    def self.serialize(results)
      Search::TagSerializer.new(results, is_collection: true).serializable_hash[:data].pluck(:attributes)
    end
    private_class_method :serialize

    def self.serialize_json_natively(results)
      tags_flat = []
      results.each do |tag|
        badge = tag.badge
        has_badge = !badge.nil?
        if has_badge
          uploader = badge.badge_image
          return nil unless uploader.is_a?(CarrierWave::Uploader::Base)

          badge_image_url = uploader.url
        else
          badge_image_url = nil
        end

        tags_flat.push(
          tag.id, tag.name, tag.hotness_score, tag.supported,
          tag.short_summary, tag.rules_html, tag.bg_color_hex,
          has_badge, badge_image_url
        )
      end

      ForemNative.serialize_search_tags_json(
        tags_flat,
        escape_html: ActiveSupport::JSON::Encoding.escape_html_entities_in_json,
      )
    end
    private_class_method :serialize_json_natively
  end
end
