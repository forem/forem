class UserActivity < ApplicationRecord
  belongs_to :user

  def set_activity!
    set_activity
    save!
  end

  def set_activity
    recently_viewed_store = user.page_views.order(created_at: :desc).limit(20).pluck(:article_id, :created_at, :time_tracked_in_seconds)
    # Now let's get all the articles where time_tracked_in_seconds for the page view from recent store is greater than 59
    recent_articles = Article.where(id: recently_viewed_store.select { |article_id, created_at, time_tracked_in_seconds| time_tracked_in_seconds > 59 }.map(&:first))

    self.last_activity_at = Time.current
    self.recently_viewed_articles = recently_viewed_store
    self.recent_tags = recent_articles.map(&:cached_tag_list).flatten.uniq.compact.first(5)
    self.recent_labels = recent_articles.map(&:cached_label_list).flatten.uniq.compact.first(5)
    self.recent_organizations = recent_articles.map(&:organization_id).uniq.compact
    self.recent_users = recent_articles.map(&:user_id).uniq.compact
    self.alltime_tags = user.cached_followed_tag_names.first(10)
  end

  def relevant_tags
    recent_tags + alltime_tags
  end
end