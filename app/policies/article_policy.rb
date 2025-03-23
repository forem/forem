class ArticlePolicy < ApplicationPolicy
  MAX_TAG_LIST_SIZE = 4

  def self.limit_post_creation_to_admins?
    FeatureFlag.enabled?(:limit_post_creation_to_admins)
  end

  def self.is_root_subforem?
    RequestStore.store[:subforem_id].present? && RequestStore.store[:subforem_id] == RequestStore.store[:root_subforem_id]
  end

  # @param query [Symbol]
  def self.include_hidden_dom_class_for?(query:)
    case query.to_sym
    when :create?, :new?, :create, :new
      # Hide the DOM if post creation is limited to admins OR if it is a root subforem
      limit_post_creation_to_admins? || is_root_subforem?
    else
      false
    end
  end

  def self.scope_users_authorized_to_action(users_scope:, action:)
    case action.to_sym
    when :create?, :new?, :create, :new
      users_scope = users_scope.without_role(:suspended)
      return users_scope unless is_root_subforem? || limit_post_creation_to_admins?
        
      users_scope.with_any_role(*Authorizer::RoleBasedQueries::ANY_ADMIN_ROLES)
    else
      raise "Unhandled predicate: #{action} for #{self}.#{__method__}"
    end
  end

  def initialize(user, record)
    @user = user
    @record = record
  end

  def feed?
    true
  end

  def has_existing_articles_or_can_create_new_ones?
    require_user!
    return true if user.articles.published.from_subforem.exists?

    create?
  rescue ApplicationPolicy::NotAuthorizedError
    false
  end

  def create?
    require_user_in_good_standing!
    # Disallow creation if it is a root subforem
    return false if self.class.is_root_subforem?

    return true unless self.class.limit_post_creation_to_admins?

    user_any_admin?
  end

  def update?
    require_user_in_good_standing!

    user_author? || user_super_admin? || user_org_admin? || user_any_admin?
  end

  def manage?
    update? && record.published? && !record.scheduled?
  end

  def stats?
    require_user!
    user_author? || user_super_admin? || user_org_admin?
  end

  def subscriptions?
    require_user!
    user_author? || user_super_admin?
  end

  def elevated_user?
    user_any_admin? || user_super_moderator?
  end

  def revoke_publication?
    require_user!
    return false unless @record.published?

    elevated_user?
  end

  def allow_tag_adjustment?
    require_user!
    elevated_user? || tag_moderator_eligible?
  end

  def tag_moderator_eligible?
    tag_ids_moderated_by_user = Tag.with_role(:tag_moderator, @user).ids
    tag_ids_moderated_by_user.size.positive?
  end

  def destroy?
    require_user!
    user_author? || user_super_admin? || user_org_admin? || user_any_admin?
  end

  def moderate?
    require_user_in_good_standing!
    return false if self.class.limit_post_creation_to_admins?
    return false if user_author?

    user.trusted? || elevated_user?
  end

  alias admin_featured_toggle? revoke_publication?
  alias toggle_featured_status? revoke_publication?
  alias can_adjust_any_tag? revoke_publication?
  alias can_perform_moderator_actions? revoke_publication?
  alias admin_unpublish? revoke_publication?
  alias new? create?
  alias delete_confirm? destroy?
  alias discussion_lock_confirm? destroy?
  alias discussion_unlock_confirm? destroy?
  alias edit? update?
  alias preview? has_existing_articles_or_can_create_new_ones?

  def permitted_attributes
    %i[title body_html body_markdown main_image published canonical_url
       description tag_list publish_under_org
       video video_code video_source_url video_thumbnail_url receive_notifications
       archived]
  end

  private

  def user_author?
    return false unless record.respond_to?(:user_id)

    record.user_id == user.id
  end

  def user_org_admin?
    user.org_admin?(record.organization_id)
  end
end
