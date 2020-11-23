class PodcastOwnershipPolicy < ApplicationPolicy
  def update?
    (user_is_owner? || user_admin?) && !user_is_banned?
  end

  def new?
    !user_is_banned?
  end

  def create?
    !user_is_banned?
  end

  def edit?
    update?
  end

  def destroy
    update?
  end

  private

  def user_is_owner?
    if record.instance_of?(PodcastOwnership)
      record.user_id == user.id
    else
      record.pluck(:user_id).uniq == [user.id]
    end
  end
end
