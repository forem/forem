module Moderator
  class Banisher
    attr_reader :user, :admin

    def self.call(admin:, offender:)
      new(offender: offender, admin: admin).banish
    end

    def initialize(admin:, offender:)
      @user = offender
      @admin = admin
    end

    def reassign_and_bust_username
      new_name = "spam_#{rand(10000)}"
      new_username = "spam_#{rand(10000)}"
      if User.find_by(name: new_name) || User.find_by(username: new_username)
        new_name = "spam_#{rand(10000)}"
        new_username = "spam_#{rand(10000)}"
      end
      user.update_columns(name: new_name, username: new_username)
      CacheBuster.new.bust("/#{user.old_username}")
      user.update_columns(old_username: nil)
    end

    def remove_profile_info
      user.update_columns(twitter_username: "", github_username: "", website_url: "", summary: "", location: "", education: "", employer_name: "", employer_url: "", employment_title: "", mostly_work_with: "", currently_learning: "", currently_hacking_on: "", available_for: "")

      user.update_columns(email_public: false, facebook_url: nil, dribbble_url: nil, medium_url: nil, stackoverflow_url: nil, behance_url: nil, linkedin_url: nil, gitlab_url: nil, mastodon_url: nil)

      user.remote_profile_image_url = "https://thepracticaldev.s3.amazonaws.com/i/99mvlsfu5tfj9m7ku25d.png" if Rails.env.production?
    end

    def add_banned_role
      user.add_role :banned
      unless user.notes.where(reason: "banned").any?
        user.notes.
          create!(reason: "banned", content: "spam account", author: admin)
      end
    end

    def delete_reactions
      user.reactions.each &:delete
    end

    def delete_comments
      return unless user.comments.count.positive?

      user.comments.each do |comment|
        comment.reactions.each &:delete
        CacheBuster.new.bust_comment(comment.commentable, user.username)
        comment.delete
      end
    end

    def delete_follows
      user.follows.each &:delete
    end

    def delete_articles
      user.articles.each do |article|
        article.reactions.each &:delete
        article.comments.each do |comment|
          comment.reactions.each &:delete
          CacheBuster.new.bust_comment(comment.commentable, comment.user.username)
          comment.delete
        end
        CacheBuster.new.bust_article(article)
        article.remove_algolia_index
        article.delete
      end
    end

    def banish
      # return unless user.comments.where("created_at < ?", 150.days.ago).empty?
      reassign_and_bust_username
      remove_profile_info
      add_banned_role
      delete_reactions
      delete_comments
      delete_articles
      delete_follows
      user.remove_from_algolia_index
      user.save!
    end
  end
end
