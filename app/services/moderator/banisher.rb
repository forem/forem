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

    def hello
      return unless user.comments.where("created_at < ?", 150.days.ago).empty?

      new_name = "spam_#{rand(10000)}"
      new_username = "spam_#{rand(10000)}"
      if User.find_by(name: new_name) || User.find_by(username: new_username)
        new_name = "spam_#{rand(10000)}"
        new_username = "spam_#{rand(10000)}"
      end
      user.name = new_name
      user.username = new_username
      user.twitter_username = ""
      user.github_username = ""
      user.website_url = ""
      user.summary = ""
      user.location = ""
      user.remote_profile_image_url = "https://thepracticaldev.s3.amazonaws.com/i/99mvlsfu5tfj9m7ku25d.png" if Rails.env.production?
      user.education = ""
      user.employer_name = ""
      user.employer_url = ""
      user.employment_title = ""
      user.mostly_work_with = ""
      user.currently_learning = ""
      user.currently_hacking_on = ""
      user.available_for = ""
      user.email_public = false
      user.facebook_url = nil
      user.dribbble_url = nil
      user.medium_url = nil
      user.stackoverflow_url = nil
      user.behance_url = nil
      user.linkedin_url = nil
      user.gitlab_url = nil
      user.mastodon_url = nil
      user.add_role :banned
      unless user.notes.where(reason: "banned").any?
        user.notes.
          create!(reason: "banned", content: "spam account", author: admin)
      end
      user.comments.each do |comment|
        comment.reactions.each { |rxn| rxn.delay.destroy! }
        comment.delay.destroy!
      end
      user.follows.each { |follow| follow.delay.destroy! }
      user.articles.each { |article| article.delay.destroy! }
      user.remove_from_index!
      user.save!
      CacheBuster.new.bust("/#{user.old_username}")
      user.update!(old_username: nil)
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
      user.update_columns(twitter_username: "", github_username: "", website_url: "", summary: "", location: "", education: "", employer_name: "", employer_url: "", employment_title: "", mostly_work_with: "", currently_learning:"", currently_hacking_on: "", available_for: "")

      user.update_columns(email_public: false, facebook_url: nil, dribbble_url: nil, medium_url: nil, stackoverflow_url: nil, behance_url: nil, linkedin_url: nil, gitlab_url: nil, mastodon_url: nil)

      user.update_columns(remote_profile_image_url: "https://thepracticaldev.s3.amazonaws.com/i/99mvlsfu5tfj9m7ku25d.png") if Rails.env.production?
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

    def clear_cache(path)
      return unless Rails.env.production?

      HTTParty.post("https://api.fastly.com/purge/https://dev.to#{path}", headers: { "Fastly-Key" => ApplicationConfig["FASTLY_API_KEY"] })
    end

    def delete_comments
      user.comments.each do |comment|
        path = comment.path
        clear_cache(path)
        comment.reactions.each &:delete
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
          comment.clear_cache(comment.path)
          comment.delete
        end
        clear_cache(article.path)
        # article.remove_from_index!
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
      delete_follows
      delete_articles
      user.remove_from_index!
      user.save!
    end
  end
end
