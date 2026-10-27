class UserActivity < ApplicationRecord
  begin
    has_neighbors :interest_embedding if column_names.include?("interest_embedding")
  rescue StandardError
    # db not available yet
  end

  belongs_to :user

  def self.update_reading_list_articles_for(user_id)
    activity = find_or_create_by(user_id: user_id)
    reading_list_articles = Reaction.readinglist.unarchived.only_articles
      .where(user_id: user_id).order(created_at: :desc).pluck(:reactable_id)
    activity.update!(alltime_reading_list_articles: reading_list_articles)
  end

  def set_activity!
    set_activity
    save!
  end

  def set_activity
    recently_viewed_store = user.page_views.order(created_at: :desc).limit(100).pluck(
      :article_id, :created_at, :time_tracked_in_seconds
    )
    # Get all the articles where time_tracked_in_seconds for the page view from recent store is > 29
    # Only select the columns used below to avoid loading body_markdown, processed_html, embeddings, etc.
    recent_articles = Article.where(id: tracked_article_ids_from(recently_viewed_store))
      .select(:id, :cached_tag_list, :cached_label_list, :organization_id, :user_id, :subforem_id)

    self.last_activity_at = Time.current
    self.recently_viewed_articles = recently_viewed_store
    assign_recent_article_metadata(recent_articles.to_a)
    self.alltime_tags = user.cached_followed_tag_names
    self.alltime_users = Follow.follower_user(user_id).pluck(:followable_id)
    self.alltime_organizations = Follow.follower_organization(user_id).pluck(:followable_id)
    self.alltime_subforems = Follow.follower_subforem(user_id).pluck(:followable_id)
    self.alltime_reading_list_articles = Reaction.readinglist.unarchived.only_articles
      .where(user_id: user_id).order(created_at: :desc).pluck(:reactable_id)
  end

  def relevant_tags(recent_tag_count = 5, all_time_tag_count = 5)
    recent_tags.first(recent_tag_count) + alltime_tags.first(all_time_tag_count)
  end

  private

  def tracked_article_ids_from(store)
    ForemNative.filter_tracked_article_ids(store, 29) || store.filter_map { |id, _ts, s| id if s > 29 }
  end

  def assign_recent_article_metadata(recent_articles)
    aggregated = ForemNative.aggregate_recent_activity_metadata(
      recent_articles.map(&:cached_tag_list), recent_articles.map(&:cached_label_list),
      recent_articles.map(&:organization_id), recent_articles.map(&:user_id),
      recent_articles.map(&:subforem_id), 5
    )
    if aggregated
      self.recent_tags, self.recent_labels, self.recent_organizations,
        self.recent_users, self.recent_subforems = aggregated
    else
      legacy_assign_recent_article_metadata(recent_articles)
    end
  end

  def legacy_assign_recent_article_metadata(recent_articles)
    self.recent_tags = recent_articles.map { |a| a.decorate.cached_tag_list_array }.flatten.uniq.compact
    self.recent_labels = recent_articles.map(&:cached_label_list).flatten.uniq.compact.first(5)
    self.recent_organizations = recent_articles.map(&:organization_id).uniq.compact
    self.recent_users = recent_articles.map(&:user_id).uniq.compact
    self.recent_subforems = recent_articles.filter_map(&:subforem_id)
  end
end
