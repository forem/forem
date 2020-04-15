namespace :temporary do
  namespace :classified_listings do
    desc "Backfill classified listings categories"
    task backfill_categories: :environment do
      ClassifiedListing::CATEGORIES_AVAILABLE.each do |key, attributes|
        category = ClassifiedListingCategory.find_or_create_by!(attributes.merge(slug: key))
        ClassifiedListing.
          where(category: key.to_s).
          update_all(classified_listing_category_id: category.id)
      end
    end
  end
end
