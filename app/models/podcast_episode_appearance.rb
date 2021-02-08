class PodcastEpisodeAppearance < ApplicationRecord
  belongs_to :user, class_name: "User", inverse_of: :podcast_episode_appearances
  belongs_to :podcast_episode
  validates :podcast_episode_id, uniqueness: { scope: :user_id }
  validates :podcast_episode_id, :user_id, :role, presence: true
  validates :role, inclusion: { in: %w[host guest], message: "provided role is not valid" }
end
