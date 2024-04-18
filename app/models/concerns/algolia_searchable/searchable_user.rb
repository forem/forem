module AlgoliaSearchable
  module SearchableUser
    extend ActiveSupport::Concern

    included do
      algoliasearch(**DEFAULT_ALGOLIA_SETTINGS, unless: :bad_actor?) do
        attribute :name, :username
        attribute :profile_image do
          profile_image_90
        end
      end
    end

    class_methods do
      def trigger_sidekiq_worker(record, delete)
        AlgoliaSearch::SearchIndexWorker.perform_async(record.class.name, record.id, delete)
      end
    end

    def bad_actor?
      score.negative? || banished? || spam_or_suspended?
    end
  end
end
