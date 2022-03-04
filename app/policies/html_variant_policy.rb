class HtmlVariantPolicy < ApplicationPolicy
  def index?
    user_any_admin?
  end

  alias show? minimal_admin?

  alias edit? minimal_admin?

  alias update? minimal_admin?

  alias new? minimal_admin?

  alias create? minimal_admin?

  alias destroy? minimal_admin?

  def permitted_attributes
    %i[html name published approved target_tag group]
  end
end
