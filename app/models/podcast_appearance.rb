class PodcastAppearance < ApplicationRecord
  belongs_to :user
  belongs_to :podcast_episode
  validates :podcast_episode_id, uniqueness: { scope: :user_id }
  validates :podcast_episode_id, :user_id, :role, presence: true
  validates :role, inclusion: { in: %w[host guest], message: "%<value> is not a valid role" }

  def podcast_episode_creator_id
    podcast_episode.podcast.creator_id
  end
end
