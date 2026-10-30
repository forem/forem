class SidebarsController < ApplicationController
  ACTIVE_DISCUSSION_LIMIT = 8
  RECENTLY_VIEWED_ARTICLE_LIMIT = 30
  layout false

  def show
    if user_signed_in?
      get_active_discussions
      set_onboarding_checklist
    end
    get_upcoming_events
  end

  private

  def get_upcoming_events
    @upcoming_events = Rails.cache.fetch("upcoming_elevated_events", expires_in: 5.minutes) do
      Event.published.elevated.includes(:page).where("end_time >= ?", Time.current).order(start_time: :asc).limit(5).to_a
    end
  end

  def get_active_discussions
    tag_names = current_user.cached_followed_tag_names
    languages = current_user.languages.pluck(:language)
    languages = [I18n.default_locale.to_s] if languages.empty?
    viewed_ids = recently_viewed_article_ids
    # Determined via field test
    order = Arel.sql("last_comment_at + (INTERVAL '1 minute' * LEAST(comment_score, 50)) DESC")

    base_scope = Article.published.from_subforem
      .where("published_at > ?", 1.week.ago)
      .with_at_least_home_feed_minimum_score

    relation = base_scope.featured
      .or(base_scope.where("comments_count >= ?", 15).where("comment_score >= ?", 25))
    if tag_names.present? || ENV["OPTIMIZED_TAGGABLE_QUERY"] != "true"
      relation = base_scope
        .where("comments_count > ?", 0)
        .cached_tagged_with_any(tag_names)
        .where(language: languages)
        .or(relation)
    end
    if viewed_ids.present?
      relation = relation.or(base_scope.where(id: viewed_ids).where("comments_count > ?", 1))
    end

    @active_discussions = relation
      .order(order)
      .limit(ACTIVE_DISCUSSION_LIMIT)
      .pluck(:path, :title, :comments_count, :created_at, :subforem_id)
  end

  def set_onboarding_checklist
    return unless Settings::General.display_sidebar_onboarding_checklist
    return if current_user.registered_at&.before?(28.days.ago)

    checklist = current_user.onboarding_checklist
    return unless checklist && !checklist.completed?

    @onboarding_checklist = checklist
  end

  # UserActivity keeps the user's latest page views (newest first) as [article_id, created_at, seconds],
  # refreshed in the background after each page view. Reading it avoids querying page_views directly,
  # which has no (user_id, created_at) index and is slow for users with a long viewing history.
  def recently_viewed_article_ids
    UserActivity.where(user_id: current_user.id).pick(:recently_viewed_articles).to_a
      .first(RECENTLY_VIEWED_ARTICLE_LIMIT)
      .filter_map(&:first)
  end
end
