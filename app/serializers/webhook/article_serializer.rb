module Webhook
  class ArticleSerializer < ApplicationSerializer
    set_type :article
    attributes :title, :description, :readable_publish_date, :cached_tag_list, :cached_tag_list_array,
               :slug, :path, :url, :comments_count, :public_reactions_count, :body_markdown

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
      CloudCoverUrl.new(a.url).call
    end
    attribute :social_image do |article|
      Articles::SocialImage.new(article).url
    end
    attribute :user do |a|
      UserSerializer.new(a.user).serializable_hash
    end
  end
end
