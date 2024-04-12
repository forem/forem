module AlgoliaSearchable
  module User
    extend ActiveSupport::Concern

    included do
      include AlgoliaSearch

      algoliasearch per_environment: true, enqueue: :trigger_sidekiq_worker, unless: :bad_actor do
        attribute :name, :username
        attribute :profile_image do
          profile_image_90
        end
      end
    end

    class_methods do
      def trigger_sidekiq_worker(record, delete)
        AlgoliaSearch::IndexWorker.perform_async(record.class.name, record.id, delete)
      end
    end

    def bad_actor
      score.negative?
    end

    def bad_actor_changed?
      score_changed? && score_was.negative? != score.negative?
    end
  end
end
