json.type_of                  "article"
json.id                       article.id
json.title                    article.title
json.description              article.description
json.cover_image              cloud_cover_url(article.main_image)
json.readable_publish_date    article.readable_publish_date
json.social_image             article_social_image_url(article)
json.tag_list                 article.cached_tag_list_array
json.tags                     article.cached_tag_list
json.slug                     article.slug
json.path                     article.path
json.url                      article.url
json.canonical_url            article.processed_canonical_url
json.comments_count           article.comments_count
json.positive_reactions_count article.positive_reactions_count
json.collection_id            article.collection_id
json.created_at               article.created_at.utc.iso8601
json.edited_at                article.edited_at&.utc&.iso8601
json.crossposted_at           article.crossposted_at&.utc&.iso8601
json.published_at             article.published_at&.utc&.iso8601
json.last_comment_at          article.last_comment_at&.utc&.iso8601
json.published_timestamp      article.published_timestamp

json.partial! "api/v0/shared/user", user: article.user
