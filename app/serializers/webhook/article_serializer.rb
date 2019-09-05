module Webhook
  class ArticleSerializer
    extend ApplicationHelper
    extend SocialImageHelper
    include FastJsonapi::ObjectSerializer

    set_type :article
    belongs_to :user
    attributes :title, :description, :readable_publish_date, :cached_tag_list, :cached_tag_list_array,
               :slug, :path, :url, :comments_count, :positive_reactions_count, :body_markdown

    attribute :canonical_url, &:processed_canonical_url
    attribute :body_html, &:processed_html
    attribute :created_at do |a|
      a.created_at.utc.iso8601
    end
    attribute :edited_at do |a|
      a.edited_at&.utc&.iso8601
    end
    attribute :crossposted_at do |a|
      a.crossposted_at&.utc&.iso8601
    end
    attribute :published_at do |a|
      a.published_at&.utc&.iso8601
    end
    attribute :last_comment_at do |a|
      a.last_comment_at&.utc&.iso8601
    end
    attribute :cover_image do |a|
      cloud_cover_url(a.main_image)
    end
    attribute :social_image do |a|
      article_social_image_url(a)
    end
  end
end
