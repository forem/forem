class PodcastAppearance < ApplicationRecord
  belongs_to :user
  belongs_to :podcast_episode
end
