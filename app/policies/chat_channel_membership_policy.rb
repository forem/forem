class ChatChannelMembershipPolicy < ApplicationPolicy

  def update?
    record.present? && user.id == record.user_id
  end
end