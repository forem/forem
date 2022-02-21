##
# @abstract
#
# The purpose of the ApplicationPolicy is to provide an application specific abstract class that
# answers questions around authorization to resources.
#
# A resource's policy (e.g. Article has an ArticlePolicy) should provide the canonical answer to the
# question: is the given user authorized to take the given action on the resource (or resource type).
#
# Authentication and Authorization are interrelated.  Authentication is about ensuring that the
# requester is who they say they are.  Authorization is about ensuring that the requester can do the
# thing they want to do.  Our policy layer _should_ be the canonical source for information
# regarding authorization.  As of <2022-02-14 Mon> that is not the case.  But this is a documentation
# and implementation refactor to begin addressing that.
#
# @note In an ideal setup our view and controller logic would **never** have the following
#       construct: `do_it if user.admin?` However we presently have lots of places in our apps and
#       views that ask those very questions.  An application's views and controllers should rarely
#       have knowledge about how policies are implemented (e.g. do this if a user has the role).
#
# @example
#   # In a Rails view
#   <%- if policy(:article).edit? %>
#     <%= link_to edit_article_path(@article) %>
#   <%- end %>
#
# @example
#   # In a Rails Controller
#   def edit
#     @article = Article.find_by(id: params[:id])
#     authorize @article
#   end
#
# @see Authorizer for details regarding user roles.
# @see https://rubygems.org/gems/pundit
class ApplicationPolicy
  attr_reader :user, :record

  # The general application policy error.  The message should include the context of why you're
  # raising this exception.
  #
  # By inheriting from Pundit::NotAuthorizedError, we can refactor our code to use an application
  # specific error instead of an error from a dependency.  This follows our pattern with
  # AbExperiment and FeatureFlag.
  class NotAuthorizedError < Pundit::NotAuthorizedError
  end

  # Raise this exception when a suspended user is attempting to take an action not allowed by a
  # suspended user.
  class UserSuspendedError < NotAuthorizedError
  end

  # Raise this exception when an action requires an authenticated user but the request has no
  # authenticated user.
  class UserRequiredError < NotAuthorizedError
  end

  # @param user [User] who's the one taking the action?
  #
  # @param record [Class, Object] what is the user acting on?  This could be a model (e.g. Article)
  #        or an instance of a model (e.g. Article.new) or any Plain Old Ruby Object [PORO].
  def initialize(user, record)
    raise UserRequiredError, I18n.t("policies.application_policy.you_must_be_logged_in") unless user

    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    scope.exists?(id: record.id)
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def manage?
    update? && record.published
  end

  def destroy?
    false
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      raise Pundit::NotAuthorizedError, I18n.t("policies.application_policy.must_be_logged_in") unless user

      @user = user
      @scope = scope
    end

    def resolve
      scope
    end
  end

  delegate :support_admin?, to: :user

  delegate :super_admin?, :any_admin?, :suspended?, to: :user, prefix: true

  alias minimal_admin? user_any_admin?
  deprecate minimal_admin?: "Deprecating #{self}#minimal_admin?, use #{self}#user_any_admin?"

  alias user_admin? user_super_admin?
  deprecate minimal_admin?: "Deprecating #{self}#user_admin?, use #{self}#user_super_admin?"

  def user_trusted?
    user.has_trusted_role?
  end
end
