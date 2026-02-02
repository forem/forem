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

    # Calculate semantic interest profile based on recent articles.
    # We weight the interests by how much we trust the signal (e.g. time spent could be a factor, 
    # but for now we'll just average the profile of articles they read > 29s)
    if recent_articles.any?
      aggregated_interests = Hash.new(0.0)
      count = 0
      
      # Create a lookup for efficient access
      articles_by_id = recent_articles.index_by(&:id)
      
      recently_viewed_store.each do |article_id, created_at, time_tracked_in_seconds|
        next unless time_tracked_in_seconds > 29 # Ensure we respect the threshold
        
        article = articles_by_id[article_id]
        next unless article && article.respond_to?(:semantic_interests) && article.semantic_interests.present?
        
        article.semantic_interests.each do |interest, score|
          aggregated_interests[interest] += score.to_f
        end
        count += 1
      end
      
      if count > 0
        # Normalize by count to get the average interest matching the range 0..1 roughly
        aggregated_interests.transform_values! { |v| (v / count).round(4) }
        
        # Keep only top interests to keep the profile lean and query efficient
        # Top 15 should be enough to capture main interests
        self.semantic_interest_profile = aggregated_interests.sort_by { |_, v| -v }.first(15).to_h
      end
    end
  end

  def relevant_tags(recent_tag_count = 5, all_time_tag_count = 5)
    recent_tags.first(recent_tag_count) + alltime_tags.first(all_time_tag_count)
  end
end