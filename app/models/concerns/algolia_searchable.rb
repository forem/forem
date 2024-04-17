module AlgoliaSearchable
  extend ActiveSupport::Concern

  DEFAULT_ALGOLIA_SETTINGS = {
    per_environment: true,
    disable_indexing: -> { Settings::General.algolia_search_enabled? == false },
    enqueue: :trigger_sidekiq_worker
  }.freeze

  included do
    include AlgoliaSearch
    public_send :include, "AlgoliaSearchable::Searchable#{name}".constantize
  end
end
