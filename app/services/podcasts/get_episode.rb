module Podcasts
  class GetEpisode
    def initialize(podcast)
      @podcast = podcast
    end

    def call(item)
      episode = podcast.existing_episode(item)
      if episode
        Podcasts::UpdateEpisode.call(episode, item)
      else
        Podcasts::CreateEpisode.call(podcast.id, item)
      end
    end

    private

    attr_reader :podcast
  end
end
