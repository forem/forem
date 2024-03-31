class HtmlVariantPolicy < ApplicationPolicy
  def index?
    user_any_admin?
  end

  alias show? user_any_admin?

  alias edit? user_any_admin?

  alias update? user_any_admin?

  alias new? user_any_admin?

  alias create? user_any_admin?

  alias destroy? user_any_admin?

  def permitted_attributes
    %i[html name published approved target_tag group]
  end
end
