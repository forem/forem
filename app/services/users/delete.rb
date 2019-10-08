module Users
  class Delete
    def initialize(user)
      @user = user
    end

    def call
      delete_comments
      delete_articles
      delete_user_activity
      user.unsubscribe_from_newsletters
      cache_buster.bust("/#{user.username}")
      user.delete
    end

    def self.call(*args)
      new(*args).call
    end

    private

    attr_reader :user

    def cache_buster
      @cache_buster ||= CacheBuster.new
    end

    def delete_user_activity
      user.notifications.delete_all
      user.reactions.delete_all
      user.follows.delete_all
      Follow.where(followable_id: user.id, followable_type: "User").delete_all
      user.messages.delete_all
      user.chat_channel_memberships.delete_all
      user.mentions.delete_all
      user.badge_achievements.delete_all
      user.github_repos.delete_all
    end

    def delete_comments
      return unless user.comments.any?

      user.comments.find_each do |comment|
        comment.reactions.delete_all
        cache_buster.bust_comment(comment.commentable)
        comment.delete
        comment.remove_notifications
      end
      cache_buster.bust_user(user)
    end

    def delete_articles
      return unless user.articles.any?

      virtual_articles = user.articles.map { |article| Article.new(article.attributes) }
      user.articles.find_each do |article|
        article.reactions.delete_all
        article.comments.includes(:user).find_each do |comment|
          comment.reactions.delete_all
          cache_buster.bust_comment(comment.commentable)
          cache_buster.bust_user(comment.user)
          comment.delete
        end
        article.remove_algolia_index
        article.delete
        article.purge
      end
      virtual_articles.each do |article|
        cachebuster.bust_article(article)
      end
    end
  end
end
