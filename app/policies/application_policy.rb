class ApplicationPolicy
  attr_reader :user, :record

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
