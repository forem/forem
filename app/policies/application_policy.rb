class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "You must be logged in" unless user

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
      raise Pundit::NotAuthorizedError, "must be logged in" unless user

      @user = user
      @scope = scope
    end

    def resolve
      scope
    end
  end

  def minimal_admin?
    user.has_role?(:super_admin) || user.has_role?(:admin)
  end

  def user_admin?
    user.has_role?(:super_admin)
  end

  def support_admin?
    user.has_role?(:support_admin)
  end

  delegate :suspended?, to: :user, prefix: true

  def user_is_trusted?
    user.has_role?(:trusted)
  end
end
