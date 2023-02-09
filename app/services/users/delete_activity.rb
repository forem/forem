module Users
  module DeleteActivity
    module_function

    def call(user)
      delete_social_media(user)
      delete_profile_info(user)
      user.api_secrets.delete_all
      user.created_podcasts.update_all(creator_id: nil)
      user.blocker_blocks.delete_all
      user.blocked_blocks.delete_all
      user.authored_notes.delete_all
      user.display_ad_events.delete_all
      user.email_messages.delete_all
      user.html_variants.delete_all
      user.poll_skips.delete_all
      user.poll_votes.delete_all
      user.response_templates.delete_all
      user.listings.destroy_all
      delete_feedback_messages(user)
    end

    # delete_all will nullify the corresponding foreign_key field because of the dependent: :nullify strategy
    def delete_feedback_messages(user)
      user.offender_feedback_messages.update_all(status: "Resolved")
      user.reporter_feedback_messages.delete_all
      user.affected_feedback_messages.delete_all
    end

    def delete_social_media(user)
      user.github_repos.delete_all
    end

    def delete_profile_info(user)
      user.notifications.delete_all
      user.reactions.delete_all
      user.reactions_to.delete_all
      user.follows.delete_all
      Follow.followable_user(user.id).delete_all
      user.mentions.delete_all
      user.badge_achievements.delete_all
      user.collections.delete_all
      user.credits.delete_all
      user.organization_memberships.delete_all
      user.profile_pins.delete_all
      user.profile.update(summary: "", location: "", website_url: "", data: {})
      user.github_username = ""
      user.twitter_username = ""
      user.facebook_username = ""
      user.save
    end
  end
end
