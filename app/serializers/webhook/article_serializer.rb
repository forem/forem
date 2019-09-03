module Webhook
  class ArticleSerializer
    include FastJsonapi::ObjectSerializer
    set_type :article
    belongs_to :user
    attributes :archived, :automatically_renew, :body_html, :body_markdown, :cached_tag_list,
               :cached_user_name, :canonical_url, :created_at, :description, :edited_at,
               :language, :main_image, :processed_html, :published, :published_at, :reading_time,
               :removed_for_abuse, :score, :slug, :title, :updated_at
  end
end
