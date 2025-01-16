module AlgoliaSearchable
  module SearchableUser
    extend ActiveSupport::Concern

    included do
      algoliasearch(**DEFAULT_ALGOLIA_SETTINGS, unless: :bad_actor_or_empty_profile?) do
        attribute :name, :username, :badge_achievements_count

        add_attribute(:profile_image) { { url: profile_image_90 } }
        # add_attribute(:profile_image_90) { profile_image_90 }
        add_attribute(:timestamp) { registered_at.to_i }
        add_replica("User_timestamp_desc", per_environment: true) { customRanking ["desc(timestamp)"] }
        add_replica("User_timestamp_asc", per_environment: true) { customRanking ["asc(timestamp)"] }
        add_replica("User_badge_achievements_count_desc",
                    per_environment: true) { customRanking ["desc(badge_achievements_count)"] }
      end
    end

    class_methods do
      def trigger_sidekiq_worker(record, delete)
        AlgoliaSearch::SearchIndexWorker.perform_async(record.class.name, record.id, delete)
      end
    end

    def bad_actor_or_empty_profile?
      score.negative? || banished? || spam_or_suspended? || (comments_count.zero? && articles_count.zero?)
    end
  end
end
