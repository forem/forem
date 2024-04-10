module AlgoliaSearchable
  module User
    extend ActiveSupport::Concern

    included do
      include AlgoliaSearch

      algoliasearch per_environment: true, enqueue: :trigger_sidekiq_worker, unless: :bad_actor do
        attribute :name, :username
        attribute :profile_image do
          # TODO: make sure profile_image_changed? works without name clash
          profile_image_90
        end

        add_replica "User_score_asc", inherit: true, per_environment: true do
          customRanking ["asc(score)"]
        end
      end
    end

    class_methods do
      def trigger_sidekiq_worker(record, delete)
        AlgoliaSearch::IndexWorker.perform_async(record.class.name, record.id, delete)
      end
    end

    def bad_actor
      # TODO: expand this
      score.negative? || spammer?
    end

    def bad_actor_changed?
      score_changed? && bad_actor
    end
  end
end
