class FeedConfig < ApplicationRecord
  has_many :feed_events, dependent: :nullify

  def score_sql(user)
    user_follow_ids = user.cached_following_users_ids
    organization_follow_ids = user.cached_following_organizations_ids
    tag_names = user.cached_followed_tag_names.first(5)
    time_of_second_latest_page_view = user&.page_views&.order(created_at: :desc)&.second&.created_at || 6.days.ago
    precomputed_selections = RecommendedArticlesList.where(user_id: user.id)
                                                     .where("expires_at > ?", Time.current)
                                                     .first&.article_ids || []
    lookback_window = time_of_second_latest_page_view - 18.hours

    terms = []

    terms << "(articles.feed_success_score * #{feed_success_weight})" if feed_success_weight.positive?
    terms << "(articles.comment_score * #{comment_score_weight})" if comment_score_weight.positive?
    terms << "(articles.score * #{score_weight})" if score_weight.positive?

    if organization_follow_weight.positive?
      org_ids = organization_follow_ids.empty? ? "-1" : organization_follow_ids.join(',')
      terms << "(CASE WHEN articles.organization_id IN (#{org_ids}) THEN #{organization_follow_weight} ELSE 0 END)"
    end

    if user_follow_weight.positive?
      user_ids = user_follow_ids.empty? ? "-1" : user_follow_ids.join(',')
      terms << "(CASE WHEN articles.user_id IN (#{user_ids}) THEN #{user_follow_weight} ELSE 0 END)"
    end

    if tag_follow_weight.positive? && tag_names.present?
      tag_condition = "CASE WHEN " + tag_names.map { |tag|
        "articles.cached_tag_list ~ '[[:<:]]#{tag}[[:>:]]'"
      }.join(' OR ') + " THEN #{tag_follow_weight} ELSE 0 END"
      terms << "(#{tag_condition})"
    end

    terms << "((1.0 / (1.0 + (EXTRACT(epoch FROM (NOW() - articles.published_at)) / 3600.0))) * #{recency_weight})" if recency_weight.positive?
    terms << "((1.0 / (1.0 + (EXTRACT(epoch FROM (NOW() - articles.last_comment_at)) / 3600.0))) * #{comment_recency_weight})" if comment_recency_weight.positive?

    if lookback_window_weight.positive?
      terms << "(CASE WHEN articles.published_at BETWEEN '#{lookback_window.utc.to_s(:db)}' AND '#{time_of_second_latest_page_view.utc.to_s(:db)}' THEN #{lookback_window_weight} ELSE 0 END)"
    end

    if precomputed_selections_weight.positive? && precomputed_selections.present?
      terms << "(CASE WHEN articles.id IN (#{precomputed_selections.join(',')}) THEN #{precomputed_selections_weight} ELSE 0 END)"
    end

    total_expression = terms.any? ? terms.join(" + ") : "0"

    <<~SQL.squish
      (#{total_expression})
    SQL
  end

  def create_slightly_modified_clone
    clone = dup
    clone.comment_recency_weight = comment_recency_weight * (1 + rand(0.0..0.1))
    clone.comment_score_weight = comment_score_weight * (1 + rand(0.0..0.1))
    clone.feed_success_weight = feed_success_weight * (1 + rand(0.0..0.1))
    clone.label_match_weight = label_match_weight * (1 + rand(0.0..0.1))
    clone.lookback_window_weight = lookback_window_weight * (1 + rand(0.0..0.1))
    clone.organization_follow_weight = organization_follow_weight * (1 + rand(0.0..0.1))
    clone.precomputed_selections_weight = precomputed_selections_weight * (1 + rand(0.0..0.1))
    clone.recency_weight = recency_weight * (1 + rand(0.0..0.1))
    clone.score_weight = score_weight * (1 + rand(0.0..0.1))
    clone.tag_follow_weight = tag_follow_weight * (1 + rand(0.0..0.1))
    clone.user_follow_weight = user_follow_weight * (1 + rand(0.0..0.1))
    clone
  end
end
