class DestroyedArticleSerializer
  include FastJsonapi::ObjectSerializer
  set_type :article
  attributes :title
end
