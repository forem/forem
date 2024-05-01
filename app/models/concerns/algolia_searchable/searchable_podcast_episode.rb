module AlgoliaSearchable
  module SearchablePodcastEpisode
    extend ActiveSupport::Concern

    included do
      include AlgoliaSearch

      algoliasearch(**DEFAULT_ALGOLIA_SETTINGS, if: :published) do
        attribute :title, :summary, :path
        attribute :podcast_name do
          podcast.title
        end
        attribute :podcast_image do
          profile_image_url
        end
      end
    end

    class_methods do
      def trigger_sidekiq_worker(record, delete)
        AlgoliaSearch::SearchIndexWorker.perform_async(record.class.name, record.id, delete)
      end
    end
  end
end
