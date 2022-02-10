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

  def update?
    user_author? || user_admin? || user_org_admin? || minimal_admin?
  end

  def admin_unpublish?
    minimal_admin?
  end

  def new?
    true
  end

  def create?
    !user_suspended?
  end

  alias delete_confirm? update?

  alias discussion_lock_confirm? update?

  alias discussion_unlock_confirm? update?

  alias destroy? update?

  alias edit? update?

  alias preview? new?

  def stats?
    user_author? || user_admin? || user_org_admin?
  end

  def permitted_attributes
    %i[title body_html body_markdown main_image published canonical_url
       description tag_list publish_under_org
       video video_code video_source_url video_thumbnail_url receive_notifications
       archived]
  end

  def subscriptions?
    user_author? || user_admin?
  end

  private

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
