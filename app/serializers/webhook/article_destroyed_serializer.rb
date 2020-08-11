module Webhook
  class ArticleDestroyedSerializer < ApplicationSerializer
    set_type :article
    attributes :title
  end
end
