class PodcastEpisodeAppearancePolicy < ApplicationPolicy
  def new?
    !user_is_banned? && user_is_podcast_owner?
  end

  def create?
    new?
  end

  def edit?
    new?
  end

  def update?
    new?
  end

  def destroy?
    new?
  end

  private

  def user_is_podcast_owner?
    return false if record.blank?

    record.podcast_episode.podcast.owner_ids.include?(user.id)
  end
end
