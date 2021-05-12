class MentionDecorator < ApplicationDecorator
  def formatted_mentionable_type
    # Articles are colloquially referred to as "posts".
    mentionable_type == "Article" ? "post" : mentionable_type.downcase
  end

  def mentioned_by_blocked_user?
    mentionable_type == "User" && UserBlock.blocking?(mentionable_id, user_id)
  end
end
