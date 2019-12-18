module Users
  module DeleteActivity
    module_function

    def call(user)
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
  end
end
