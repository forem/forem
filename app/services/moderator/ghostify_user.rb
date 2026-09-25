module Moderator
  class GhostifyUser
    def self.call(...)
      new(...).call
    end

    def initialize(target_user_id:, action_user_id:)
      @target_user_id = target_user_id
      @action_user_id = action_user_id
    end

    def call
      user = User.find_by(id: target_user_id)
      return unless user
      
      ghost_user_id = ::Settings::Community.ghost_user_id
      return unless ghost_user_id.present?
      
      ghost_user = User.find_by(id: ghost_user_id)
      return unless ghost_user

      target_articles_ids = user.articles.ids
      target_comments_ids = user.comments.ids

      user.articles.find_each do |article|
        article.user_id = ghost_user.id
        article.save(validate: false)
      end

      user.comments.find_each do |comment|
        comment.user_id = ghost_user.id
        comment.save(validate: false)
      end

      payload = {
        target_user_id: target_user_id,
        ghost_user_id: ghost_user.id,
        target_article_ids: target_articles_ids,
        target_comment_ids: target_comments_ids,
        action: "ghostify_user"
      }
      
      action_user = User.find_by(id: action_user_id)
      Audit::Logger.log(:moderator, action_user, payload)
    end

    private

    attr_reader :target_user_id, :action_user_id
  end
end
