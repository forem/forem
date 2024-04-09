module AlgoliaSearchable
  module User
    extend ActiveSupport::Concern

    included do
      include AlgoliaSearch

      algoliasearch per_environment: true, enqueue: :trigger_sidekiq_worker, unless: :bad_actor do
        attribute :name, :username
        attribute :profile_image do
          # TODO: make sure profile_image_changed? wil work without name clash
          :profile_image_90
        end

        # might need organizations
        # attribute :organizations do
        #   organizations.map(&:name)
        # end
      end
    end

    class_methods do
      def trigger_sidekiq_worker(record, delete)
        # TODO: check if this get called by banish_user through callback, with test
        AlgoliaSearch::IndexWorker.perform_async(record.class.name, record.id, delete)
      end
    end

    def bad_actor
      # TODO: expand this
      calculated_score.negative? || spammer?
    end
    alias bad_actor_changed? bad_actor
  end
end
