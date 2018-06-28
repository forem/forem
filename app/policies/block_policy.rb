class BlockPolicy < ApplicationPolicy
  def index?
    user_is_admin?
  end

  def show?
    user_is_admin?
  end

  def new?
    user_is_admin?
  end

  def edit?
    user_is_admin?
  end

  def create?
    user_is_admin?
  end

  def update?
    user_is_admin?
  end

  def destroy?
    user_is_admin?
  end

  def permitted_attributes
    %i[input_html input_css input_javascript featured index_position publish_now]
  end
end
