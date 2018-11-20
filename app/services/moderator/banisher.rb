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

    def banish
      # return unless user.comments.where("created_at < ?", 7.days.ago).empty?
      ban_offender
      strip_user_profile
      destroy_dependents
      user.remove_from_index!
    end

    def destroy_dependents
      destroy_reactions
      destroy_comments
      destroy_articles
      destroy_follows
    end

    def ban_offender
      user.add_role :banned
      unless user.notes.where(reason: "banned").any?
        user.notes.
          create!(reason: "banned", content: "spam account", author_id: admin.id)
      end
    end

    def destroy_follows
      user.follows.destroy_all
    end
    handle_asynchronously :destroy_follows

    def destroy_reactions
      user.reactions.destroy_all
    end

    def destroy_comments
      user.comments.destroy_all
    end
    handle_asynchronously :destroy_comments

    def destroy_articles
      user.articles.destroy_all
    end
    handle_asynchronously :destroy_articles

    def bust_user_cache(old_username)
      CacheBuster.new.bust("/#{old_username}")
    end

    def strip_user_profile
      bust_user_cache(user.username)
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
      user.save
      user.update_columns(old_username: nil)
    end
  end
end
