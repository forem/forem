module Moderator
  class BanishUser < ManageActivityAndRoles
    DEFAULT_PROFILE_IMAGE =
      "https://thepracticaldev.s3.amazonaws.com/i/99mvlsfu5tfj9m7ku25d.png".freeze

    attr_reader :user, :admin

    def self.call(admin:, user:)
      new(user: user, admin: admin).banish
    end

    def initialize(admin:, user:)
      super(user: user, admin: admin, user_params: {})
    end

    def banish
      BanishedUser.create(username: user.username, banished_by: admin)
      user.unsubscribe_from_newsletters if user.email?
      remove_profile_info
      handle_user_status("Suspend", "spam account")
      delete_user_activity
      delete_comments
      delete_articles
      Users::CleanupChatChannels.call(user)
      reassign_and_bust_username
      delete_vomit_reactions
    end

    private

    def reassign_and_bust_username
      new_name = "spam_#{rand(1_000_000)}"
      new_username = "spam_#{rand(1_000_000)}"
      if User.find_by(name: new_name) || User.find_by(username: new_username)
        new_name = "spam_#{rand(1_000_000)}"
        new_username = "spam_#{rand(1_000_000)}"
      end
      user.update_columns(name: new_name, username: new_username, old_username: user.username,
                          profile_updated_at: Time.current)
      EdgeCache::Bust.call("/#{user.old_username}")
    end

    def remove_profile_info
      user.profile.clear!
      user.update_columns(profile_image: DEFAULT_PROFILE_IMAGE)
    end

    def delete_vomit_reactions
      Reaction.where(reactable: user, category: "vomit").delete_all
    end
  end
end
