json.array! @stories do |article|
  json.partial! "api/v0/shared/article", article: article
end
