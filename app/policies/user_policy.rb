class UserPolicy < ApplicationPolicy
  def edit?
    current_user?
  end

  def onboarding_update?
    true
  end

  def onboarding_checkbox_update?
    true
  end

  def update?
    current_user?
  end

  def update_twitch_username?
    current_user?
  end

  def update_language_settings?
    current_user?
  end

  def destroy?
    current_user?
  end

  def confirm_destroy?
    current_user?
  end

  def full_delete?
    current_user?
  end

  def request_destroy?
    current_user?
  end

  def join_org?
    !user_is_banned?
  end

  def leave_org?
    OrganizationMembership.exists?(user_id: user.id, organization_id: record.id)
  end

  def remove_association?
    current_user?
  end

  def dashboard_show?
    current_user? || user_admin? || minimal_admin?
  end

  def pro_user?
    current_user? && user.pro?
  end

  def moderation_routes?
    user.has_role?(:trusted) && !user.banned
  end

  def permitted_attributes
    email_attributes | thirdy_party_attributes | user_attributes | config_attributes
  end

  def email_attributes
    %i[
      email
      email_badge_notifications
      email_comment_notifications
      email_community_mod_newsletter
      email_connect_messages
      email_digest_periodic
      email_follower_notifications
      email_membership_newsletter
      email_mention_notifications
      email_newsletter
      email_public
      email_tag_mod_newsletter
      email_unread_notifications
    ]
  end

  def social_attributes
    %i[
      facebook_url
      gitlab_url
      instagram_url
      linkedin_url
      mastodon_url
      medium_url
      twitch_url
      twitch_username
    ]
  end

  def user_attributes
    %i[
      available_for
      behance_url
      contact_consent
      currently_hacking_on
      currently_learning
      education
      employer_name
      employer_url
      employment_title
      experience_level
      location
      looking_for_work
      looking_for_work_publicly
      name
      password
      password_confirmation
      profile_image
      stackoverflow_url
      summary
      username
      website_url
    ]
  end

  def config_attributes
    %i[
      bg_color_hex
      config_font
      config_theme
      config_navbar
      display_sponsors
      dribbble_url
      editor_version
      export_requested
      feed_admin_publish_permission
      feed_mark_canonical
      feed_referential_link
      feed_url
      inbox_guidelines
      inbox_type
      mobile_comment_notifications
      mod_roundrobin_notifications
      mostly_work_with
      permit_adjacent_sponsors
      text_color_hex
    ]
  end

  private

  def not_self?
    user != record
  end

  def current_user?
    user == record
  end
end
