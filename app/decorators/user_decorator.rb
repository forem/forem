class UserDecorator < ApplicationDecorator
  delegate_all

  def cached_followed_tags
    Rails.cache.fetch("user-#{id}-#{updated_at}/followed_tags", expires_in: 100.hours) do
      Tag.where(id: Follow.where(follower_id: id, followable_type: "ActsAsTaggableOn::Tag").pluck(:followable_id)).order("hotness_score DESC")
    end
  end
end
