class ChatChannelMembershipPolicy < ApplicationPolicy
  def update?
    record.present? && user.id == record.user_id
  end

  def find_by_chat_channel_id?
    record.present? && user.id == record.user_id
  end

  def destroy?
    record.present? && user.id == record.user_id
  end

  def leave_membership?
    record.present? && user.id == record.user_id
  end

  def update_membership?
    record.present? && user.id == record.user_id
  end

  def invitation?
    record.present? && user.id == record.user_id
  end

  def chat_channel_info?
    record.present? && user.id == record.user_id
  end

  def request_details?
    record.present? && user.id == record.user_id
  end
end
