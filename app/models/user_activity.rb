class UserActivity < ApplicationRecord
  belongs_to :user

  def set_activity!
    set_activity
    save!
  end

  def set_activity
    recently_viewed_store = user.page_views.order(created_at: :desc).limit(100).pluck(:article_id, :created_at, :time_tracked_in_seconds)
    # Now let's get all the articles where time_tracked_in_seconds for the page view from recent store is greater than 29
    recent_articles = Article.where(id: recently_viewed_store.select { |article_id, created_at, time_tracked_in_seconds| time_tracked_in_seconds > 29 }.map(&:first))

    self.last_activity_at = Time.current
    self.recently_viewed_articles = recently_viewed_store
    self.recent_tags = recent_articles.map { |a| a.decorate.cached_tag_list_array }.flatten.uniq.compact
    self.recent_labels = recent_articles.map(&:cached_label_list).flatten.uniq.compact.first(5)
    self.recent_organizations = recent_articles.map(&:organization_id).uniq.compact
    self.recent_users = recent_articles.map(&:user_id).uniq.compact
    self.recent_subforems = recent_articles.map(&:subforem_id).compact # Purposefully not unique because we want to tabulate volume by subforem
    self.alltime_tags = user.cached_followed_tag_names
    self.alltime_users = Follow.follower_user(user_id).pluck(:followable_id)
    self.alltime_organizations = Follow.follower_organization(user_id).pluck(:followable_id)
    self.alltime_subforems = Follow.follower_subforem(user_id).pluck(:followable_id)
  end

  def relevant_tags(recent_tag_count = 5, all_time_tag_count = 5)
    recent_tags.first(recent_tag_count) + alltime_tags.first(all_time_tag_count)
  end
end