#  @note When we destroy the related user, it's using dependent:
#        :delete for the relationship.  That means no before/after
#        destroy callbacks will be called on this object.
class PodcastEpisodeAppearance < ApplicationRecord
  belongs_to :user, class_name: "User", inverse_of: :podcast_episode_appearances
  belongs_to :podcast_episode
  validates :podcast_episode_id, uniqueness: { scope: :user_id }
  validates :role, presence: true
  validates :role,
            inclusion: { in: %w[host guest],
                         message: I18n.t("models.podcast_episode_appearance.provided_role_is_not_valid") }
end
