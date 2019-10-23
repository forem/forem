class InternalPolicy < ApplicationPolicy
  def access?
    user.has_any_role?(
      { name: :single_resource_admin, resource: record },
      :super_admin,
      :admin,
    )
  end
end
