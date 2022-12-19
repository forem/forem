class ArticlePolicy < ApplicationPolicy
  MAX_TAG_LIST_SIZE = 4
  # @return [TrueClass] when only Forem admins can post an Article.
  # @return [FalseClass] when most any Forem user can post an Article.
  #
  # @note This is for Authorization System: use case 1-1.  At present, this is the quickest way to
  #       refactor our code to deliver on that feature.
  #
  # @see https://github.com/forem/forem/pull/16437 for pattern of adding a predicate method to the
  #      "most relevant" class.
  # @see https://github.com/orgs/forem/projects/46 for project details
  def self.limit_post_creation_to_admins?
    FeatureFlag.enabled?(:limit_post_creation_to_admins)
  end

  # @param query [Symbol] the name of one of the ArticlePolicy action predicates (e.g. :create?,
  #        :new?) though as a convenience, we will also accept :new, and :create.
  # @return [TrueClass] if this query should default to hidden
  # @return [FalseClass] if this query should not be hidden in the UI.
  #
  # @note The symmetry of the case statement structure with .scope_users_authorized_to_action
  def self.include_hidden_dom_class_for?(query:)
    case query.to_sym
    when :create?, :new?, :create, :new
      limit_post_creation_to_admins?
    else
      false
    end
  end

  # Helps filter a `:users_scope` to those authorized to the `:action`.  I want a list of all users
  # who can create an Article.  This policy method can help with that.
  #
  # @param users_scope [ActiveRecord::Relation] a scope for querying user objects
  # @param action [Symbol] the name of one of the ArticlePolicy action predicates (e.g. :create?,
  #        :new?) though as a convenience, we will also accept :new, and :create.
  #
  # @return [ActiveRecord::Relation]
  #
  # @see https://api.rubyonrails.org/classes/ActiveRecord/Scoping/Named/ClassMethods.html#method-i-scope
  #
  # @note With this duplication it would be feasible to alter the instance method logics to use the
  #       class method (e.g. `ArticlePolicy.scope_authorized(users_scope: User, action:
  #       :create?).find_by(user.id)`) but that's a future consideration.
  #
  # @note This is not a Pundit scope (see https://github.com/varvet/pundit#scopes), as those methods
  #       are for answering "What articles can I see?"  This method is for answering "Who all can
  #       <action> on Articles?"
  #
  # @note Why isn't this a User.scope method?  Because the logic of who can take an action on the
  #       resource is the problem domain of the policy.
  #
  # @note The symmetry of the case statement structure with .include_hidden_dom_class_for?
  def self.scope_users_authorized_to_action(users_scope:, action:)
    case action.to_sym
    when :create?, :new?, :create, :new
      # Note the delicate dance to duplicate logic in a general sense.  [I hope that] this is a
      # stop-gap solution.
      users_scope = users_scope.without_role(:suspended)
      return users_scope unless limit_post_creation_to_admins?

      # NOTE: Not a fan of reaching over to the constant of another class, but I digress.
      users_scope.with_any_role(*Authorizer::RoleBasedQueries::ANY_ADMIN_ROLES)
    else
      # Not going to implement all of the use cases.
      raise "Unhandled predicate: #{action} for #{self}.#{__method__}"
    end
  end

  # @note [@jeremyf] I am re-implemnenting the initialize method, but removing the Pundit
  #       authorization.  There's an assumption that all policy questions will require a user,
  #       unless you know specifically that they don't.
  #
  # @note as a reminder, if you attempt to authorize this policy in a controller with that calls
  #       {CachingHeaders#set_cache_control_headers} you may encounter some headaches.  What do
  #       those headaches look like?  When you call {CachingHeaders#set_cache_control_headers}, you
  #       are likely disallowing checks on current_user (via {EdgeCacheSafetyCheck#current_user}).
  #
  # @todo [@jeremyf] I don't like altering the initializer and its core assumption.  But the other
  #       option to get Articles working for https://github.com/forem/forem/issues/16529 is to
  #       address the at present fundamental assumption regarding "Policies are for authorizing when
  #       you have a user, otherwise let the controller decide."
  #
  # rubocop:disable Lint/MissingSuper
  #
  # @see even Rubocop thinks this is a bad idea.  But the short-cut gets me unstuck.  I hope there's
  #      enough breadcrumbs to undo this short-cut.
  def initialize(user, record)
    @user = user
    @record = record
  end
  # rubocop:enable Lint/MissingSuper

  def feed?
    true
  end

  # Does the user already have existing articles?  Can they create an article?
  #
  # @return [TrueClass] They have existing published articles OR can create new ones.
  # @return [FalseClass] They do not have published articles NOR can they create new ones.
  #
  # @note As part of our aspirations to only show users what is relevant to them and "hiding" what
  #       is not, this method will help us with the edge case of "should we show the user a
  #       dashboard listing of posts?"
  #
  # @note This handles the case in which a user has lost the ability to create posts (e.g. we've
  #       toggled on the feature limiting posts to admins only) but they have at least one published
  #       post.  In that case we want to show them things like "their posts's analytics" or a
  #       dashboard of their published posts.
  #
  # @note This policy method is a bit different.  It is strictly meant to return true or false.
  #       Other policies might raise exceptions, but the purpose of this method is for conditional
  #       rendering.
  def has_existing_articles_or_can_create_new_ones?
    require_user!
    return true if user.articles.published.exists?

    create?
  rescue ApplicationPolicy::NotAuthorizedError
    false
  end

  # @see {ArticlePolicy.scope_users_authorized_to_action} for "mirrored" details.
  def create?
    require_user_in_good_standing!
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

  # this method performs the same checks that determine:
  # if the record can be featured
  # if user can adjust any tag
  # if user can perform moderator actions
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
    return false unless tag_ids_moderated_by_user.size.positive?

    adjustments = TagAdjustment.where(article_id: @record.id)
    has_room_for_tags = @record.tag_list.size < MAX_TAG_LIST_SIZE
    # ensures that mods cannot adjust an already-adjusted tag
    # "zero?" because intersection has just one integer (0 or 1)
    has_no_relevant_adjustments = adjustments.pluck(:tag_id).intersection(tag_ids_moderated_by_user).size.zero?

    # tag_mod can add their moderated tags
    return true if has_room_for_tags && has_no_relevant_adjustments

    authorized_to_adjust = @record.tags.ids.intersection(tag_ids_moderated_by_user).size.positive?

    # tag_mod can remove their moderated tags
    !has_room_for_tags && has_no_relevant_adjustments && authorized_to_adjust
  end

  def destroy?
    require_user!

    user_author? || user_super_admin? || user_org_admin? || user_any_admin?
  end

  def moderate?
    # Technically, we could check the limit_post_creation_to_admins? first, but [@jeremyf]'s
    # operating on a "trying to maintain consistency" approach.
    require_user_in_good_standing!

    return false if self.class.limit_post_creation_to_admins?

    # <2022-05-09 Mon> Don't let a user moderate their own article; though this may not be the desired behavior.
    return false if user_author?

    # Beware a trusted user does not guarantee that they are an admin.  And more specifically, being
    # an admin does not guarantee being trusted.
    return true if user.trusted?

    elevated_user?
  end

  alias admin_featured_toggle? revoke_publication?

  alias toggle_featured_status? revoke_publication?

  alias can_adjust_any_tag? revoke_publication?

  alias can_perform_moderator_actions? revoke_publication?

  # Due to the associated controller method "admin_unpublish", we
  # alias "admin_ubpublish" to the "revoke_publication" method.
  alias admin_unpublish? revoke_publication?

  alias new? create?

  alias delete_confirm? destroy?

  alias discussion_lock_confirm? destroy?

  alias discussion_unlock_confirm? destroy?

  alias edit? update?

  # The ArticlesController#preview method is very complicated but aspirationally, we want to ensure
  # that someone can preview an article of their if they already have a published article or they
  # can create new ones.
  alias preview? has_existing_articles_or_can_create_new_ones?

  def permitted_attributes
    %i[title body_html body_markdown main_image published canonical_url
       description tag_list publish_under_org
       video video_code video_source_url video_thumbnail_url receive_notifications
       archived]
  end

  private

  def user_author?
    # We might have the Article class (instead of the Article instance), so let's short circuit
    return false unless record.respond_to?(:user_id)

    record.user_id == user.id
  end

  def user_org_admin?
    user.org_admin?(record.organization_id)
  end
end
