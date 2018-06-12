AlgoliaSearch.configuration = { application_id: ENV["ALGOLIASEARCH_APPLICATION_ID"], api_key: ENV["ALGOLIASEARCH_API_KEY"] }

if Rails.env.test?
  ENV["ALGOLIASEARCH_PUBLIC_SEARCH_ONLY_KEY"] = "TEST_KEY"
else
  # Restrtict Access to private indices
  params = {
    restrictIndices: "searchables_#{Rails.env},ordered_articles_#{Rails.env},ordered_articles_by_published_at_#{Rails.env},ordered_articles_by_positive_reactions_count_#{Rails.env},ordered_comments_#{Rails.env}",
  }
  secured_algolia_key = Algolia.generate_secured_api_key(
    ENV["ALGOLIASEARCH_SEARCH_ONLY_KEY"], params,
  )

  ENV["ALGOLIASEARCH_PUBLIC_SEARCH_ONLY_KEY"] = secured_algolia_key
end