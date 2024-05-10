module AlgoliaSearchable
  module SearchableArticle
    extend ActiveSupport::Concern

    included do
      include AlgoliaSearch

      algoliasearch(**DEFAULT_ALGOLIA_SETTINGS, if: :indexable) do
        attribute :user do
          { name: user.name,
            username: user.username,
            profile_image: user.profile_image_90,
            id: user.id,
            profile_image_90: user.profile_image_90 }
        end

        attribute :title, :tag_list, :reading_time, :score, :featured, :comments_count,
                  :positive_reactions_count, :path, :main_image, :user_id

        add_attribute(:published_at) { published_at.to_i }
        add_attribute(:readable_publish_date) { readable_publish_date }
        add_attribute(:timestamp) { published_at.to_i }
        add_replica("Article_timestamp_desc", per_environment: true) { customRanking ["desc(timestamp)"] }
        add_replica("Article_timestamp_asc", per_environment: true) { customRanking ["asc(timestamp)"] }
      end
    end

    class_methods do
      def trigger_sidekiq_worker(record, delete)
        AlgoliaSearch::SearchIndexWorker.perform_async(record.class.name, record.id, delete)
      end
    end

    def indexable
      published && score.positive?
    end

    def indexable_changed?
      published_changed? || score_changed?
    end
  end
end
