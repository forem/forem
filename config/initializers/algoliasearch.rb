AlgoliaSearch.configuration = {
  application_id: ApplicationConfig["ALGOLIASEARCH_APPLICATION_ID"],
  api_key: ApplicationConfig["ALGOLIASEARCH_API_KEY"]
}

if !Rails.env.test?
  # Restrtict Access to private indices
  params = {
    restrictIndices: "searchables_#{Rails.env},ordered_articles_#{Rails.env},ordered_articles_by_published_at_#{Rails.env},ordered_articles_by_positive_reactions_count_#{Rails.env},ordered_comments_#{Rails.env}",
  }
  secured_algolia_key = Algolia.generate_secured_api_key(
    ApplicationConfig["ALGOLIASEARCH_SEARCH_ONLY_KEY"], params,
  )

  ApplicationConfig["ALGOLIASEARCH_PUBLIC_SEARCH_ONLY_KEY"] = secured_algolia_key
end
