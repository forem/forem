module Exporter
  class Articles
    attr_reader :name, :user

    def initialize(user)
      @name = :articles
      @user = user
    end

    def export(slug: nil)
      articles = user.articles
      articles = articles.where(slug: slug) if slug.present?

      { "#{name}.json" => jsonify(articles) }
    end

    private

    def allowed_attributes
      time_attributes | url_attributes | general_attributes
    end

    def time_attributes
      %i[
        created_at
        crossposted_at
        edited_at
        last_comment_at
        published_at
      ]
    end

    def url_attributes
      %i[
        canonical_url
        feed_source_url
        video_closed_caption_track_url
        video_source_url
        video_thumbnail_url
      ]
    end

    def general_attributes
      %i[
        body_markdown
        cached_tag_list
        cached_user_name
        cached_user_username
        comments_count
        description
        main_image
        main_image_background_hex_color
        path
        public_reactions_count
        processed_html
        published
        published_from_feed
        show_comments
        slug
        social_image
        title
        video
        video_code
      ]
    end

    def jsonify(articles)
      articles_to_jsonify = []

      # load articles in batches and select only needed attributes
      articles.select([:id] + allowed_attributes).find_each do |article|
        articles_to_jsonify << article
      end

      articles_to_jsonify.to_json(only: allowed_attributes)
    end
  end
end
