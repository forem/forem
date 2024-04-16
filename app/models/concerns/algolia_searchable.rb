module AlgoliaSearchable
  extend ActiveSupport::Concern

  # TODO: Make sure trigger_sidekiq_worker is called in ALL important places, ie all update_column area
  DEFAULT_ALGOLIA_SETTINGS = {
    per_environment: true,
    disable_indexing: -> { Settings::General.algolia_search_enabled? == false },
    enqueue: :trigger_sidekiq_worker
  }.freeze

  included do
    public_send :include, "AlgoliaSearchable::Searchable#{name}".constantize
  end
end
