module AlgoliaSearchable
  extend ActiveSupport::Concern

  included do
    if Settings::General.algolia_search_enabled?
      public_send :include, "AlgoliaSearchable::#{name}".constantize
    end
    # TODO: Make sure trigger_sidekiq_worker is called in ALL important places, ie all update_column area
  end
end
