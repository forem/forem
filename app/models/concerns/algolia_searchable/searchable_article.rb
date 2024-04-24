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
                  :reaction_counts, :positive_reaction_counts, :path
        # TODO: what about bookmark status?

        attribute :main_image # TODO: main_image_90 ?

        attribute :published_at do
          published_at.to_i
        end
      end
    end

    class_methods do
      def trigger_sidekiq_worker(record, delete)
        # TODO: umm make sure this get called in the appropriate place
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
