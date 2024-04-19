module AlgoliaSearchable
  module SearchableOrganization
    extend ActiveSupport::Concern

    included do
      algoliasearch(**DEFAULT_ALGOLIA_SETTINGS) do
        attribute :name, :tag_line, :summary, :slug
        attribute :path do
          slug
        end
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

    def path_changed?
      slug_changed?
    end
  end
end
