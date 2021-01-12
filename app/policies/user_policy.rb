class UserPolicy < ApplicationPolicy
  PERMITTED_ATTRIBUTES = %i[
    reaction_notifications
    available_for
    behance_url
    bg_color_hex
    config_font
    config_theme
    config_navbar
    currently_hacking_on
    currently_learning
    display_announcements
    display_sponsors dribbble_url
    editor_version education email
    email_badge_notifications
    email_comment_notifications
    email_community_mod_newsletter
    email_connect_messages
    email_digest_periodic
    email_follower_notifications
    email_membership_newsletter
    email_mention_notifications
    email_newsletter email_public
    email_tag_mod_newsletter
    email_unread_notifications
    employer_name
    employer_url
    employment_title
    experience_level
    export_requested
    facebook_url
    youtube_url
    feed_admin_publish_permission
    feed_mark_canonical
    feed_referential_link
    feed_url
    gitlab_url
    inbox_guidelines
    inbox_type
    instagram_url
    linkedin_url
    location
    mastodon_url
    medium_url
    mobile_comment_notifications
    mod_roundrobin_notifications
    welcome_notifications
    mostly_work_with
    name
    password
    password_confirmation
    payment_pointer
    permit_adjacent_sponsors
    profile_image
    stackoverflow_url
    summary
    text_color_hex
    twitch_url
    username
    website_url
  ].freeze

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

  def remove_identity?
    current_user?
  end

  def dashboard_show?
    current_user? || user_admin? || minimal_admin?
  end

  def pro_user?
    current_user? && user.pro?
  end

  def moderation_routes?
    (user.has_role?(:trusted) || minimal_admin?) && !user.banned
  end

  def permitted_attributes
    PERMITTED_ATTRIBUTES
  end

  private

  def not_self?
    user != record
  end

  def current_user?
    user == record
  end
end
