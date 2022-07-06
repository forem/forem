json.type_of "listing"

json.extract!(
  listing,
  :id,
  :title,
  :slug,
  :body_markdown,
  :category,
  :processed_html,
  :published,
)

json.listing_category_id listing.classified_listing_category_id
json.tag_list            listing.cached_tag_list
json.tags                listing.tag_list
json.created_at          utc_iso_timestamp(listing.created_at)
