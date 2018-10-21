class HtmlVariantPolicy < ApplicationPolicy
  def index?
    user_admin?
  end

  def show?
    user_admin?
  end

  def edit?
    user_admin?
  end

  def update?
    user_admin?
  end

  def new?
    user_admin?
  end

  def create?
    user_admin?
  end

  def destroy?
    user_admin?
  end

  def permitted_attributes
    %i[html name published approved]
  end
end
