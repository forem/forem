module Users
  module DeleteActivity
    module_function

    # If you're removing data that is in Elasticsearch, make sure to use
    # .destroy_all to trigger the callback to remove the document(s)
    def call(user)
      delete_social_media(user)
      delete_profile_info(user)
      user.access_grants.delete_all
      user.access_tokens.delete_all
      user.api_secrets.delete_all
      user.created_podcasts.update_all(creator_id: nil)
      user.blocker_blocks.delete_all
      user.blocked_blocks.delete_all
      user.webhook_endpoints.delete_all
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

    # delete_all will nullify the corresponding foreign_key field bacause of the dependent: :nullify strategy
    def delete_feedback_messages(user)
      user.offender_feedback_messages.delete_all
      user.reporter_feedback_messages.delete_all
      user.affected_feedback_messages.delete_all
    end

    def delete_social_media(user)
      user.github_repos.delete_all
    end

    def delete_profile_info(user)
      user.notifications.delete_all
      user.reactions.delete_all
      user.follows.delete_all
      Follow.followable_user(user.id).delete_all
      user.messages.delete_all
      Users::CleanupChatChannels.call(user)
      user.mentions.delete_all
      user.badge_achievements.delete_all
      user.collections.delete_all
      user.credits.delete_all
      user.organization_memberships.delete_all
      user.profile_pins.delete_all
    end
  end
end
