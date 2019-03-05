class HtmlVariantPolicy < ApplicationPolicy
  def index?
    minimal_admin?
  end

  def show?
    minimal_admin?
  end

  def edit?
    minimal_admin?
  end

  def update?
    minimal_admin?
  end

  def new?
    minimal_admin?
  end

  def create?
    minimal_admin?
  end

  def destroy?
    minimal_admin?
  end

  def permitted_attributes
    %i[html name published approved target_tag group]
  end
end
