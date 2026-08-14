class EventPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    record.published? || user&.administrative_access_to?(resource: Event)
  end

  def create?
    user&.administrative_access_to?(resource: Event)
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  class Scope < Scope
    def resolve
      if user&.administrative_access_to?(resource: Event)
        scope.all
      else
        scope.published
      end
    end
  end
end
