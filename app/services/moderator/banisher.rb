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
  end
end
