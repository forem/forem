##
# @abstract
#
# The purpose of the ApplicationPolicy is to provide an application specific abstract class that
# answers questions around authorization to resources.
#
# A resource's policy (e.g. Article has an ArticlePolicy) should provide the canonical answer to the
# question: is the given user authorized to take the given action on the resource (or resource type).
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

  # @param user [User] who's the one taking the action?
  #
  # @param record [Class, Object] what is the user acting on?  This could be a model (e.g. Article)
  #        or an instance of a model (e.g. Article.new) or any Plain Old Ruby Object [PORO].
  def initialize(user, record)
    raise Pundit::NotAuthorizedError, I18n.t("policies.application_policy.you_must_be_logged_in") unless user

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

  def minimal_admin?
    user.any_admin?
  end

  def user_admin?
    user.super_admin?
  end

  delegate :support_admin?, to: :user

  delegate :suspended?, to: :user, prefix: true

  def user_trusted?
    user.has_trusted_role?
  end
end
