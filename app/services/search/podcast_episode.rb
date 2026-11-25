module Search
  class PodcastEpisode
    ATTRIBUTES = %w[
      body
      comments_count
      id
      podcast_id
      processed_html
      published_at
      quote
      reactions_count
      slug
      subtitle
      summary
      title
      website_url
    ].freeze
    private_constant :ATTRIBUTES

    DEFAULT_PER_PAGE = 60
    private_constant :DEFAULT_PER_PAGE

    MAX_PER_PAGE = 120 # to avoid querying too many items, we set a maximum amount for a page
    private_constant :MAX_PER_PAGE

    def self.search_documents(page: 0, per_page: DEFAULT_PER_PAGE, sort_by: nil, sort_direction: nil, term: nil,
                              format: :hash)
      # NOTE: [@rhymes/atsmith813] we should eventually update the frontend
      # to start from page 1
      page = page.to_i + 1
      per_page = [(per_page || DEFAULT_PER_PAGE).to_i, MAX_PER_PAGE].min

      relation = ::PodcastEpisode
        .reachable
        .where(podcast_id: Podcast.published)
        .includes(:podcast)
        .references(:podcasts)
      relation = relation.search_podcast_episodes(term) if term.present?
      relation = relation.select(*ATTRIBUTES)
      relation = sort(relation, sort_by, sort_direction)
      results = relation.page(page).per(per_page)

      if format == :json && ForemNative.available? && Time.zone&.tzinfo&.name == "Etc/UTC"
        json = serialize_json_natively(results)
        return Homepage::ArticleSerializer::EncodedJson.new(json) if json
      end

      serialize(results)
    end

    def self.sort(relation, sort_by, sort_direction)
      return relation.reorder(sort_by => sort_direction) if sort_by && sort_direction

      relation.reorder(nil)
    end
    private_class_method :sort

    def self.serialize(results)
      Search::PodcastEpisodeSerializer
        .new(results, is_collection: true)
        .serializable_hash[:data]
        .pluck(:attributes)
    end
    private_class_method :serialize

    def self.serialize_json_natively(results)
      podcast_images_by_id = {}
      episodes_flat = []

      results.each do |ep|
        podcast = ep.podcast
        return nil unless podcast

        published_at = ep.published_at
        if published_at.nil?
          pub_sec = nil
          pub_millis = 0
        elsif published_at.respond_to?(:tv_sec) && published_at.respond_to?(:tv_nsec)
          pub_sec = published_at.tv_sec
          pub_millis = published_at.tv_nsec / 1_000_000
        else
          return nil
        end

        podcast_image_url = podcast_images_by_id[podcast.id] ||= podcast.profile_image_url_for(length: 90)
        episodes_flat.push(
          ep.id, ep.body, ep.comments_count, ep.slug, podcast.slug,
          pub_sec, pub_millis, ep.quote, ep.reactions_count,
          ep.subtitle, ep.summary, ep.title, ep.website_url, podcast_image_url
        )
      end

      ForemNative.serialize_search_podcast_episodes_json(
        episodes_flat,
        escape_html: ActiveSupport::JSON::Encoding.escape_html_entities_in_json,
      )
    end
    private_class_method :serialize_json_natively
  end
end
