module Concepts
  class DailyMetricsWorker
    include Sidekiq::Job
    sidekiq_options queue: :low_priority, lock: :until_executing, on_conflict: :replace

    def perform(date_str = nil)
      date =
        if date_str.present?
          begin
            Date.parse(date_str)
          rescue Date::Error, ArgumentError
            Rails.logger.error("Concepts::DailyMetricsWorker invalid date_str=#{date_str.inspect}")
            return
          end
        else
          Date.yesterday
        end
      start_time = date.beginning_of_day
      end_time = date.end_of_day

      Concept.find_each do |concept|
        # Direct memberships
        article_ids = concept.concept_memberships.where(record_type: "Article").pluck(:record_id)
        comment_ids = concept.concept_memberships.where(record_type: "Comment").pluck(:record_id)

        # 1. New articles directly mapped
        articles_count = 0
        if article_ids.any?
          articles_count = Article.published
            .where(id: article_ids, published_at: start_time..end_time).count
        end

        # 2. Page views on mapped articles
        page_views = 0
        if article_ids.any?
          page_views = PageView
            .where(article_id: article_ids, created_at: start_time..end_time)
            .sum(:counts_for_number_of_views)
        end

        # 3. Reactions: on mapped articles + on mapped comments
        reactions_count = 0
        if article_ids.any?
          reactions_count += Reaction
            .where(reactable_type: "Article", reactable_id: article_ids, created_at: start_time..end_time)
            .count
        end
        if comment_ids.any?
          reactions_count += Reaction
            .where(reactable_type: "Comment", reactable_id: comment_ids, created_at: start_time..end_time)
            .count
        end

        # 4. Comments count: directly mapped comments + comments under mapped articles
        direct_comments_count = 0
        if comment_ids.any?
          direct_comments_count = Comment.where(id: comment_ids, created_at: start_time..end_time).count
        end

        under_articles_comments_count = 0
        if article_ids.any?
          under_articles_comments_count = Comment
            .where(commentable_type: "Article", commentable_id: article_ids, created_at: start_time..end_time)
            .count
        end

        comments_count = direct_comments_count + under_articles_comments_count

        # Compute a composite popularity score:
        # - Each new article: 10.0 points
        # - Each comment: 2.0 points
        # - Each reaction: 1.0 point
        # - Each page view: 0.1 points (10 page views = 1.0 point)
        popularity_score = (articles_count * 10.0) +
          (reactions_count * 1.0) +
          (comments_count * 2.0) +
          (page_views * 0.1)

        metric = concept.concept_daily_metrics.find_or_initialize_by(date: date)
        metric.update!(
          articles_count: articles_count,
          page_views: page_views,
          reactions_count: reactions_count,
          comments_count: comments_count,
          popularity_score: popularity_score,
        )
      end
    end
  end
end
