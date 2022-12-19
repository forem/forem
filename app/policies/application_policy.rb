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

  # @param user [Object] the "user" (person?) we're attempting to authorize.
  # @return [TrueClass] if we have a "user" (whatever that object might be, we'll assume the callers
  #         know what they're doing) and that user is not suspended
  #
  # @raise [ApplicationPolicy::UserSuspendedError] if our user suspended
  # @raise [ApplicationPolicy::UserRequiredError] if our given user was "falsey"
  #
  # @see ApplicationPolicy.require_user!
  # @note [@jeremyf] I'm choosing to make this a class method (even though later I define an
  #       instance method) because this question is something that we often ask outside of our
  #       current policy implementation.  By making this class method, I can begin to factor those
  #       policy implementations to at least a common thing that we use within our policies.
  def self.require_user_in_good_standing!(user:)
    require_user!(user: user)

    return true unless user.suspended?

    raise ApplicationPolicy::UserSuspendedError, I18n.t("policies.application_policy.your_account_is_suspended")
  end

  # @param user [Object] the "user" (person?) we're attempting to authorize.
  # @return [TrueClass] if we have a "user" (whatever that object might be, we'll assume the callers
  #         know what they're doing)
  #
  # @raise [ApplicationPolicy::UserRequiredError] if our user is "falsey"
  #
  # @note [@jeremyf] I'm choosing to make this a class method (even though later I define an
  #       instance method) because this question is something that we often ask outside of our
  #       current policy implementation.  By making this class method, I can begin to factor those
  #       policy implementations to at least a common thing that we use within our policies.
  def self.require_user!(user:)
    return true if user

    raise ApplicationPolicy::UserRequiredError, I18n.t("policies.application_policy.you_must_be_logged_in")
  end

  # This method provides a means for creating consistent DOM classes for "policy" related HTML elements.
  #
  # @param record [Object] what object are we testing our policy?
  # @param query [String,Symbol] what query are we asking of the object's corresponding policy?
  #
  # @note This method's signature maps to pundit's `policy` helper method and the implicit chained
  #       call (e.g. `policy(Article).create?`)
  #
  # @see Pundit::Authorization.policy pundit's #policy helper method
  # @see Pundit::PolicyFinder
  #
  # @return [String] a dom class compliant string, see the corresponding specs for expected values.
  def self.dom_classes_for(record:, query:)
    dom_classes = [base_dom_class_for(record: record, query: query)]
    # I don't want the Policy instance, because due to construction, that could raise an exception.
    # The class will do just fine.
    policy_class = Pundit::PolicyFinder.new(record).policy
    dom_classes << "hidden" if policy_class&.include_hidden_dom_class_for?(query: query)
    dom_classes.join(" ")
  end

  def self.base_dom_class_for(record:, query:)
    fragments = %w[js policy]
    case record
    when Symbol
      fragments << record.to_s.underscore
    when Class
      fragments << record.model_name.name.underscore
    when ActiveRecord::Base
      fragments << record.model_name.name.underscore
      fragments << (record.id.presence || "new")
    end
    fragments << query.to_s.underscore.delete("?").to_s
    fragments.join("-")
  end

  # @api private
  # @abstract
  #
  # @param query [Symbol] the method name we would be calling on the policy instance.
  # @return [TrueClass] if we should hide the dom element.
  # @return [FalseClass] if we should not hide the dom element.
  # rubocop:disable Lint/UnusedMethodArgument
  def self.include_hidden_dom_class_for?(query:)
    false
  end
  # rubocop:enable Lint/UnusedMethodArgument

  # @param user [User] who's the one taking the action?
  #
  # @param record [Class, Object] what is the user acting on?  This could be a model (e.g. Article)
  #        or an instance of a model (e.g. Article.new) or any Plain Old Ruby Object [PORO].
  def initialize(user, record)
    @user = user
    @record = record

    require_user!
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

  delegate :super_moderator?, :super_admin?, :any_admin?, :suspended?, to: :user, prefix: true

  alias minimal_admin? user_any_admin?
  deprecate minimal_admin?: "Deprecating #{self}#minimal_admin?, use #{self}#user_any_admin?"

  alias user_admin? user_super_admin?
  deprecate minimal_admin?: "Deprecating #{self}#user_admin?, use #{self}#user_super_admin?"

  def user_trusted?
    user.has_trusted_role?
  end

  protected

  def require_user!
    self.class.require_user!(user: user)
  end

  def require_user_in_good_standing!
    self.class.require_user_in_good_standing!(user: user)
  end
end
