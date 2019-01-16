module Exporter
  class Articles
    attr_reader :name
    attr_reader :user

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
      %i[
        body_markdown
        cached_tag_list
        cached_user_name
        cached_user_username
        canonical_url
        comments_count
        created_at
        crossposted_at
        description
        edited_at
        feed_source_url
        language
        last_comment_at
        main_image
        main_image_background_hex_color
        path
        positive_reactions_count
        processed_html
        published
        published_at
        published_from_feed
        show_comments
        slug
        social_image
        title
        video
        video_closed_caption_track_url
        video_code
        video_source_url
        video_thumbnail_url
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
