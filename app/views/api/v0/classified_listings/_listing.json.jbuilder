json.type_of "classified_listing"

json.extract!(
  listing,
  :id,
  :title,
  :slug,
  :body_markdown,
  :category,
  :classified_listing_category_id,
  :processed_html,
  :published,
)

json.tag_list listing.cached_tag_list
json.tags     listing.tag_list
