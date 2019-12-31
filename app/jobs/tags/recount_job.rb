module Tags
  class RecountJob < ApplicationJob
    queue_as :tag_recount

    def perform(article_id)
      article = Article.find_by(id: article_id).decorate
      return unless article

      article.cached_tag_list_array.each do |tag_name|
        @tag = Tag.find_by(name: tag_name)
        next unless @tag

        @plucked_article_ids = Article.cached_tagged_with(@tag).pluck(:id)

        count_articles
        count_comments
        count_reactions
      end
    end

    def count_articles
      articles_this_7_days_count = Article.cached_tagged_with(@tag).published.where("published_at > ?", 7.days.ago).size
      SortableCount.find_or_create_by(countable_id: @tag.id, countable_type: "ActsAsTaggableOn::Tag", slug: "published_articles_this_7_days").update_column(:number, articles_this_7_days_count)
      articles_prior_7_days_count = Article.cached_tagged_with(@tag).published.where("published_at > ? AND published_at < ?", 14.days.ago, 7.days.ago).size
      SortableCount.find_or_create_by(countable_id: @tag.id, countable_type: "ActsAsTaggableOn::Tag", slug: "published_articles_prior_7_days").update_column(:number, articles_prior_7_days_count)
      articles_prior_7_days_count = 0.5 if comments_prior_7_days_count.zero? # Guard against zero division
      SortableCount.find_or_create_by(countable_id: @tag.id, countable_type: "ActsAsTaggableOn::Tag", slug: "published_articles_change_7_days").
        update_column(:number, articles_this_7_days_count / articles_prior_7_days_count.to_f)
    end

    def count_comments
      comments_this_7_days_count = Comment.where(commentable_id: @plucked_article_ids).where("created_at > ?", 7.days.ago).size
      SortableCount.find_or_create_by(countable_id: @tag.id, countable_type: "ActsAsTaggableOn::Tag", slug: "comments_this_7_days").update_column(:number, comments_this_7_days_count)
      comments_prior_7_days_count = Comment.where(commentable_id: @plucked_article_ids).where("created_at > ? AND created_at < ?", 14.days.ago, 7.days.ago).size
      SortableCount.find_or_create_by(countable_id: @tag.id, countable_type: "ActsAsTaggableOn::Tag", slug: "comments_prior_7_days").update_column(:number, comments_prior_7_days_count)
      comments_prior_7_days_count = 0.5 if comments_prior_7_days_count.zero? # Guard against zero division
      SortableCount.find_or_create_by(countable_id: @tag.id, countable_type: "ActsAsTaggableOn::Tag", slug: "comments_change_7_days").
        update_column(:number, comments_this_7_days_count / comments_prior_7_days_count.to_f)
    end

    def count_reactions
      reactions_this_7_days_count = Reaction.where(reactable_id: @plucked_article_ids).where("created_at > ?", 7.days.ago).size
      SortableCount.find_or_create_by(countable_id: @tag.id, countable_type: "ActsAsTaggableOn::Tag", slug: "reactions_this_7_days").update_column(:number, reactions_this_7_days_count)
      reactions_prior_7_days_count = Reaction.where(reactable_id: @plucked_article_ids).where("created_at > ? AND created_at < ?", 14.days.ago, 7.days.ago).size
      SortableCount.find_or_create_by(countable_id: @tag.id, countable_type: "ActsAsTaggableOn::Tag", slug: "reactions_prior_7_days").update_column(:number, reactions_prior_7_days_count)
      reactions_prior_7_days_count = 0.5 if comments_prior_7_days_count.zero? # Guard against zero division
      SortableCount.find_or_create_by(countable_id: @tag.id, countable_type: "ActsAsTaggableOn::Tag", slug: "reactions_change_7_days").
        update_column(:number, reactions_this_7_days_count / reactions_prior_7_days_count.to_f)
    end
  end
end
