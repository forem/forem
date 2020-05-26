module Articles
  class AnalyticsUpdater
    def initialize(user, context = "default")
      @context = context
      @user = user
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      qualified_articles = get_articles_that_qualify(published_articles)
      return if qualified_articles.none?

      fetch_and_update_page_views_and_reaction_counts(qualified_articles)
    end

    private

    attr_reader :user

    def fetch_and_update_page_views_and_reaction_counts(qualified_articles)
      qualified_articles.each_slice(15) do |chunk|
        chunk.each do |article|
          article.update_columns(previous_public_reactions_count: article.public_reactions_count)
          # Notification.send_milestone_notification(type: "Reaction", article_id: article.id)
          # Notification.send_milestone_notification(type: "View", article_id: article.id)
        end
      end
    end

    def get_articles_that_qualify(articles_to_check)
      qualified_articles = []
      articles_to_check.each do |article|
        qualified_articles << article if should_fetch(article)
      end
      qualified_articles
    end

    def should_fetch(article)
      return true if @context == "force"

      article.public_reactions_count > article.previous_public_reactions_count || occasionally_force_fetch?
    end

    def occasionally_force_fetch?
      rand(25) == 1
    end

    def published_articles
      user.articles.published
    end
  end
end
