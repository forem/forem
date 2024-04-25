module AlgoliaSearchable
  module SearchableArticle
    extend ActiveSupport::Concern

    included do
      include AlgoliaSearch

      algoliasearch(**DEFAULT_ALGOLIA_SETTINGS, if: :indexable) do
        attribute :user do
          { name: user.name, username: user.username, profile_image: user.profile_image_90 }
        end

        attribute :title, :tag_list, :reading_time, :score, :featured, :featured_number, :comments_count,
                  :reaction_counts, :positive_reaction_counts, :path, :main_image

        attribute :published_at do
          published_at.to_i
        end
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
