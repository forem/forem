class MessagePolicy < ApplicationPolicy
  def create?
    !user.spam_or_suspended?
  end

  def destroy?
    user_sender?
  end

  alias update? destroy?

  def permitted_attributes_for_update
    %i[message_markdown]
  end

  private

  def user_sender?
    record.user_id == user.id
  end
end
