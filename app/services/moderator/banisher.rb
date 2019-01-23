module Moderator
  class Banisher
    attr_reader :user, :admin

    def self.call_banish(admin:, offender:)
      new(offender: offender, admin: admin).banish
    end

    def self.call_delete_activity(admin:, offender:)
      new(offender: offender, admin: admin).full_delete
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

    def delete_comments
      return unless user.comments.any?

      user.comments.find_each do |comment|
        comment.reactions.delete_all
        CacheBuster.new.bust_comment(comment.commentable, user.username)
        comment.delete
      end
    end

    def delete_articles
      return unless user.articles.any?

      user.articles.find_each do |article|
        article.reactions.delete_all
        article.comments.find_each do |comment|
          comment.reactions.delete_all
          CacheBuster.new.bust_comment(comment.commentable, comment.user.username)
          comment.delete
        end
        CacheBuster.new.bust_article(article)
        article.remove_algolia_index
        article.delete
      end
    end

    def delete_user_activity
      user.notifications.delete_all
      user.reactions.delete_all
      user.follows.delete_all
      Follow.where(followable_id: user.id, followable_type: "User").delete_all
      user.chat_channel_memberships.delete_all
      user.mentions.delete_all
      user.badge_achievements.delete_all
      user.github_repos.delete_all
      delete_comments
      delete_articles
    end

    def full_delete
      delete_user_activity
      CacheBuster.new.bust("/#{user.old_username}")
      user.delete
    end

    def banish
      reassign_and_bust_username
      remove_profile_info
      add_banned_role
      delete_user_activity
      user.remove_from_algolia_index
      user.save!
    end
  end
end
