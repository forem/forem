module Users
  module DeletePodcasts
    def self.call(user)
      return unless user

      user.podcast_ownerships.includes(:podcast).find_each do |ownership|
        # The podcast's cache bust is enqueued in the same transaction that
        # deletes it, so if enqueuing fails a retry finds the ownership again.
        PodcastOwnership.transaction do
          ownership.destroy

          podcast = ownership.podcast
          # Guard against ownership without podcast
          next if podcast.blank?

          # We have another owner, don't delete the podcast.
          next if PodcastOwnership.where(podcast: podcast).where.not(user_id: user.id).exists?

          # No sense keeping the roles around.
          Role.where(resource: podcast).destroy_all

          podcast.destroy
          # We'll want to bust the paths of the podcasts we deleted.
          if podcast.path.present?
            Podcasts::BustCacheWorker.perform_in(BustCacheBaseWorker::AFTER_COMMIT_DELAY, podcast.path)
          end
        end
      end
    end
  end
end
