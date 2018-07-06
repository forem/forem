class UserPolicy < ApplicationPolicy
  def edit?
    user == record
  end

  def onboarding_update?
    true
  end

  def update?
    user == record
  end

  def join_org?
    !user_is_banned?
  end

  def leave_org?
    true
  end

  def add_org_admin?
    user.org_admin && within_the_same_org?
  end

  def remove_org_admin?
    user.org_admin && not_self? && within_the_same_org?
  end

  def remove_from_org?
    user.org_admin && not_self? && within_the_same_org?
  end

  def dashboard_show?
    current_user? || user_is_admin?
  end

  def moderation_routes?
    user.has_role?(:trusted) && !user.banned
  end

  def permitted_attributes
    %i[available_for
       bg_color_hex
       contact_consent
       currently_hacking_on
       currently_learning
       display_sponsors
       education
       email
       email_badge_notifications
       email_comment_notifications
       email_digest_periodic
       email_follower_notifications
       email_membership_newsletter
       email_mention_notifications
       email_newsletter
       email_public
       email_unread_notifications
       employer_name
       employer_url
       employment_title
       feed_admin_publish_permission
       feed_mark_canonical
       feed_url
       location
       looking_for_work
       looking_for_work_publicly
       mentee_description
       mentor_description
       mostly_work_with
       name
       offering_mentorship
       permit_adjacent_sponsors
       password
       password_confirmation
       prefer_language_en
       prefer_language_es
       prefer_language_fr
       prefer_language_it
       prefer_language_ja
       profile_image
       seeking_mentorship
       summary
       text_color_hex
       username
       website_url]
  end

  private

  def within_the_same_org?
    user.organization == record.organization
  end

  def not_self?
    user != record
  end

  def current_user?
    user == record
  end
end
