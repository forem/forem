module AlgoliaSearchable
  module SearchableComment
    extend ActiveSupport::Concern

    included do
      include AlgoliaSearch

      algoliasearch(**DEFAULT_ALGOLIA_SETTINGS, unless: :bad_comment?) do
        attribute :commentable_id, :commentable_type, :path, :parent_id, :title
        attribute :body do
          title
        end

        attribute :published_at do
          readable_publish_date
        end

        attribute :user do
          { name: user.name,
            username: user.username,
            profile_image: user.profile_image_90,
            profile_image_90: user.profile_image_90 }
        end

        add_attribute(:timestamp) { created_at.to_i }
        add_replica("Comment_timestamp_desc", per_environment: true) { customRanking ["desc(timestamp)"] }
        add_replica("Comment_timestamp_asc", per_environment: true) { customRanking ["asc(timestamp)"] }
      end
    end

    class_methods do
      def trigger_sidekiq_worker(record, delete)
        AlgoliaSearch::SearchIndexWorker.perform_async(record.class.name, record.id, delete)
      end
    end

    def bad_comment?
      score.negative?
    end
  end
end
