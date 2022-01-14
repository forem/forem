class InternalPolicy < ApplicationPolicy
  def access?
    user.administrative_access_to?(resource: record)
  end
end
