class UserPolicy < ApplicationPolicy
  PERMITTED_ATTRIBUTES = %i[
    reaction_notifications
    available_for
    bg_color_hex
    config_font
    config_theme
    config_navbar
    current_password
    currently_hacking_on
    currently_learning
    display_announcements
    display_sponsors
    editor_version education email
    email_badge_notifications
    email_comment_notifications
    email_community_mod_newsletter
    email_digest_periodic
    email_follower_notifications
    email_membership_newsletter
    email_mention_notifications
    email_newsletter
    email_public
    email_tag_mod_newsletter
    email_unread_notifications
    employer_name
    employer_url
    employment_title
    experience_level
    export_requested
    feed_mark_canonical
    feed_referential_link
    feed_url
    inbox_guidelines
    inbox_type
    mobile_comment_notifications
    mod_roundrobin_notifications
    welcome_notifications
    name
    password
    password_confirmation
    payment_pointer
    permit_adjacent_sponsors
    profile_image
    text_color_hex
    username
  ].freeze

  def edit?
    current_user?
  end

  alias remove_identity? edit?
  alias update_password? edit?

  # The analytics? policy method is also on the OrganizationPolicy.  This exists specifically to allow for
  # "duck-typing" on the tests.
  alias analytics? edit?

  def onboarding_update?
    true
  end

  alias onboarding_checkbox_update? onboarding_update?

  alias onboarding_notifications_checkbox_update? onboarding_update?

  def update?
    edit? && !user_suspended?
  end

  alias destroy? edit?

  alias confirm_destroy? edit?

  alias full_delete? edit?

  alias request_destroy? edit?

  def join_org?
    !user_suspended?
  end

  def leave_org?
    OrganizationMembership.exists?(user_id: user.id, organization_id: record.id)
  end

  def dashboard_show?
    current_user? || user_super_admin? || user_any_admin?
  end

  def elevated_user?
    user_any_admin? || user_super_moderator?
  end

  alias toggle_suspension_status? elevated_user?
  alias unpublish_all_articles? elevated_user?

  def moderation_routes?
    (user.has_trusted_role? || elevated_user?) && !user.suspended?
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
