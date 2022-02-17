class ArticlePolicy < ApplicationPolicy
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

  # @note [@jeremyf] I am re-implemnenting the initialize method, but removing the Pundit
  #       authorization.  There's an assumption that all policy questions will require a user,
  #       unless you know specifically that they don't.
  #
  # @todo [@jeremyf] I don't like altering the initializer and its core assumption.  But the other
  #       option to get Articles working for https://github.com/forem/forem/issues/16529 is to
  #       address the at present fundamental assumption regarding "Policies are for authorizing when
  #       you have a user, otherwise let the controller decide."
  #
  # rubocop:disable Lint/MissingSuper
  #
  # @see even Rubocop thinks this is a bad idea.  But the short-cut gets me unstuck.  I hope there's
  # enough breadcrumbs to undo this short-cut.
  def initialize(user, record)
    @user = user
    @record = record
  end
  # rubocop:enable Lint/MissingSuper

  def update?
    require_user!
    user_author? || user_super_admin? || user_org_admin? || user_any_admin?
  end

  def admin_unpublish?
    require_user!
    user_any_admin?
  end

  def admin_featured_toggle?
    minimal_admin?
  end

  # @note It is likely that we want this to mirror `:create?` in the future.  As it stands, we can
  #       use this value to "triangulate" towards a simplifying solution to
  #       https://github.com/forem/forem/issues/16529 (Also, I added this comment so that this code
  #       appears with the pull request)
  #
  # @note For backwards compatability purposes, we're not checking if there's a user.
  def new?
    true
  end

  def create?
    require_user!
    !user_suspended?
  end

  alias delete_confirm? update?

  alias discussion_lock_confirm? update?

  alias discussion_unlock_confirm? update?

  alias destroy? update?

  alias edit? update?

  alias preview? new?

  def stats?
    require_user!
    user_author? || user_super_admin? || user_org_admin?
  end

  def permitted_attributes
    %i[title body_html body_markdown main_image published canonical_url
       description tag_list publish_under_org
       video video_code video_source_url video_thumbnail_url receive_notifications
       archived]
  end

  def subscriptions?
    require_user!
    user_author? || user_super_admin?
  end

  private

  def require_user!
    return if user

    raise Pundit::NotAuthorizedError, I18n.t("policies.application_policy.you_must_be_logged_in")
  end

  def user_author?
    if record.instance_of?(Article)
      record.user_id == user.id
    else
      record.pluck(:user_id).uniq == [user.id]
    end
  end

  def user_org_admin?
    user.org_admin?(record.organization_id)
  end
end
