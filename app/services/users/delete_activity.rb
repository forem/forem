module Users
  module DeleteActivity
    module_function

    BATCH_SIZE = 1_000

    def call(user)
      delete_social_media(user)
      delete_profile_info(user)
      user.api_secrets.delete_all
      user.created_podcasts.update_all(creator_id: nil)
      user.blocker_blocks.delete_all
      user.blocked_blocks.delete_all
      user.authored_notes.delete_all
      user.billboard_events.delete_all
      delete_in_batches(user.email_messages)
      user.html_variants.delete_all
      user.poll_skips.delete_all
      user.poll_votes.delete_all
      user.response_templates.delete_all
      user.listings.destroy_all
      UserActivity.where(user_id: user.id).delete_all
      AiAudit.where(affected_user_id: user.id).update_all(affected_user_id: nil)
      delete_feedback_messages(user)
    end

    # delete_all will nullify the corresponding foreign_key field because of the dependent: :nullify strategy
    def delete_feedback_messages(user)
      user.offender_feedback_messages.update_all(status: "Resolved")
      user.reporter_feedback_messages.delete_all
      user.affected_feedback_messages.delete_all
    end

    # Tables that can hold a lot of rows for a single user are deleted in
    # batches so no single statement runs into the statement timeout. Only use
    # this for associations whose delete_all deletes (not nullifies) rows.
    def delete_in_batches(relation)
      relation.in_batches(of: BATCH_SIZE).delete_all
      # unlike an association's own delete_all, this doesn't reset loaded records
      relation.reset
    end

    def delete_social_media(user)
      user.github_repos.delete_all
    end

    def delete_profile_info(user)
      delete_in_batches(user.notifications)
      delete_in_batches(user.reactions)
      delete_in_batches(user.reactions_to)
      delete_in_batches(user.follows)
      delete_in_batches(Follow.followable_user(user.id))
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
