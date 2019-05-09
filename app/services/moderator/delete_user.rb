module Moderator
  class DeleteUser < ManageActivityAndRoles
    attr_reader :user, :admin, :user_params

    def initialize(admin:, user:, user_params:)
      @user = user
      @admin = admin
      @user_params = user_params
    end

    def self.call_deletion(admin:, user:, user_params:)
      if user_params[:ghostify] == "true"
        new(user: user, admin: admin, user_params: user_params).ghostify
      else
        new(user: user, admin: admin, user_params: user_params).full_delete
      end
    end

    def ghostify
      @ghost = User.find_by(username: "ghost")
      reassign_articles
      reassign_comments
      delete_non_content_activity_and_user
    end

    def full_delete
      delete_comments
      delete_articles
      delete_non_content_activity_and_user
    end

    private

    def delete_non_content_activity_and_user
      delete_user_activity
      user.unsubscribe_from_newsletters
      CacheBuster.new.bust("/#{user.username}")
      user.delete
    end

    def reassign_comments
      return unless user.comments.any?

      user.comments.find_each do |comment|
        comment.update_columns(user_id: @ghost.id)
        comment.save
        comment.path
      end
    end

    def reassign_articles
      return unless user.articles.any?

      user.articles.find_each do |article|
        path = "/#{@ghost.username}/" + article.slug
        article.update_columns(user_id: @ghost.id, path: path)
      end
    end
  end
end
