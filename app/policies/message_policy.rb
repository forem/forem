class MessagePolicy < ApplicationPolicy
  def create?
    !user_suspended?
  end

  def destroy?
    user_is_sender?
  end

  def update?
    destroy?
  end

  def permitted_attributes_for_update
    %i[message_markdown]
  end

  private

  def user_is_sender?
    record.user_id == user.id
  end
end
