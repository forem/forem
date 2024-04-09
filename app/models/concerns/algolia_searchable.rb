module AlgoliaSearchable
  extend ActiveSupport::Concern

  included do
    if Settings::General.algolia_search_enabled?
      public_send :include, "AlgoliaSearchable::#{name}".constantize
    end
  end
end
