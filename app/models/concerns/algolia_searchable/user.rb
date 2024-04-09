module AlgoliaSearchable
  module User
    extend ActiveSupport::Concern

    included do
      include AlgoliaSearch

      algoliasearch per_environment: true, enqueue: :trigger_sidekiq_worker, unless: :bad_actor do
        attribute :name, :username, :profile_image_90

        # might need organizations
        # attribute :organizations do
        #   organizations.map(&:name)
        # end

        attributesForFaceting :username
      end
    end

    class_methods do
      def trigger_sidekiq_worker(record, delete)
        # TODO: check if this get called by banish_user through callback, with test
        AlgoliaSearch::IndexWorker.perform_async(record.class.name, record.id, delete)
      end
    end

    # I don't like the profile_image_90 method name

    def bad_actor
      # TODO: expand this
      calculated_score.negative? || spammer?
    end
    alias bad_actor_changed? bad_actor
  end
end
