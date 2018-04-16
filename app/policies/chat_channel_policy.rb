class ChatChannelPolicy < ApplicationPolicy
  def moderate?
    !user_is_banned? && user_is_admin?
  end
end
