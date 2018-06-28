class ChatChannelPolicy < ApplicationPolicy

  def index?
    user
  end

  def moderate?
    !user_is_banned? && user_is_admin?
  end

  def show?
    user_part_of_channel_or_open
  end

  def open?
    user_part_of_channel
  end

  private

  def user_part_of_channel_or_open
    record.present? && (record.channel_type == "open" || record.has_member?(user))
  end

  def user_part_of_channel
    record.present? && record.has_member?(user)
  end
end
