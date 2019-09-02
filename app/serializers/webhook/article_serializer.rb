module Webhook
  class ArticleSerializer
    include FastJsonapi::ObjectSerializer
    set_type :article
    attributes :title, :body_markdown, :processed_html, :published, :cached_tag_list
  end
end
