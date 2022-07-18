module Users
  module DeletePodcasts
    def self.call(user)
      return unless user

      # We'll want to bust the podcast paths that match our criteria.
      paths = []
      user.podcast_ownerships.includes(:podcast).find_each do |ownership|
        ownership.destroy

        podcast = ownership.podcast
        # Guard against ownership without podcast
        next if podcast.blank?

        # We have another owner, don't delete the podcast.
        next if PodcastOwnership.where(podcast: podcast).where.not(user_id: user.id).exists?

        # No sense keeping the roles around.
        Role.where(resource: podcast).destroy_all

        paths << podcast.path if podcast.path.present?

        podcast.destroy
      end

      paths.each do |path|
        EdgeCache::BustPodcast.call(path)
      end
    end
  end
end
