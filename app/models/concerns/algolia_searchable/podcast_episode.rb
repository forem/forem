module AlgoliaSearchable
  module PodcastEpisode
    extend ActiveSupport::Concern

    included do
      include AlgoliaSearch

      algoliasearch per_environment: true, enqueue: :trigger_sidekiq_worker, if: :published do
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
        AlgoliaSearch::IndexWorker.perform_async(record.class.name, record.id, delete)
      end
    end

    def podcast_name_changed?
      # TODO: this probably wouldn't work, need callback from Podcast instead
      postcast.title_changed?
    end

    def path_changed?
      # TODO: path_changed? probably wouldn't work either because it neeed the parent's info
      slug_changed? || podcast.slug_changed?
    end
  end
end
