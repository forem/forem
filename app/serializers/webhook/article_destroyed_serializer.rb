module Webhook
  class ArticleDestroyedSerializer
    include FastJsonapi::ObjectSerializer
    set_type :article
    attributes :title
  end
end
