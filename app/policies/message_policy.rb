class MessagePolicy < ApplicationPolicy
  def create?
    !user_suspended?
  end

  def destroy?
    user_sender?
  end

  def update?
    destroy?
  end

  def permitted_attributes_for_update
    %i[message_markdown]
  end

  private

  def user_sender?
    record.user_id == user.id
  end
end
