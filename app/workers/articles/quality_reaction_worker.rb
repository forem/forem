module Articles
  class QualityReactionWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: 10, lock: :until_and_while_executing

    def perform
      return unless mascot_user

      # Process each discoverable subforem
      Subforem.cached_discoverable_ids.each do |subforem_id|
        process_subforem_articles(subforem_id)
      end
    end

    private

    def process_subforem_articles(subforem_id)
      # Get articles from the past day with score >= 0 and no existing mascot reactions
      eligible_articles = Article.published
        .where(subforem_id: subforem_id)
        .where("published_at > ?", 1.day.ago)
        .where("score >= 0")
        .where(type_of: "full_post")
        .where.not(id: Reaction.where(user: mascot_user, category: %w[thumbsup thumbsdown]).select(:reactable_id))
        .order(score: :desc)
        .limit(18)
        .includes(:user, :comments)

      return if eligible_articles.count < 5

      # Assess quality and get best/worst articles using AI with subforem context
      assessment = Ai::ArticleQualityAssessor.new(eligible_articles, subforem_id: subforem_id).assess

      return if assessment[:best].nil?

      # Issue thumbs up to the best article
      issue_thumbs_up(assessment[:best])

      # Only issue thumbs down if we have at least 12 articles
      if eligible_articles.count >= 12 && assessment[:worst]
        issue_thumbs_down(assessment[:worst])
        Rails.logger.info(
          "QualityReactionWorker: Subforem #{subforem_id} - Issued thumbs up to article #{assessment[:best].id} " \
          "and thumbs down to article #{assessment[:worst].id}",
        )
      else
        Rails.logger.info(
          "QualityReactionWorker: Subforem #{subforem_id} - Issued thumbs up to article #{assessment[:best].id} " \
          "(only #{eligible_articles.count} eligible articles, skipping thumbs down)",
        )
      end
    end

    def mascot_user
      @mascot_user ||= User.mascot_account
    end

    def issue_thumbs_up(article)
      # Remove any existing thumbs down from mascot
      Reaction.where(
        user: mascot_user,
        reactable: article,
        category: "thumbsdown",
      ).destroy_all

      # Create thumbs up reaction
      Reaction.create!(
        user: mascot_user,
        reactable: article,
        category: "thumbsup",
        status: "confirmed",
      )

      # Mark article as featured
      article.update(featured: true)
    end

    def issue_thumbs_down(article)
      # Remove any existing thumbs up from mascot
      Reaction.where(
        user: mascot_user,
        reactable: article,
        category: "thumbsup",
      ).destroy_all

      # Create thumbs down reaction
      Reaction.create!(
        user: mascot_user,
        reactable: article,
        category: "thumbsdown",
        status: "confirmed",
      )
    end
  end
end
