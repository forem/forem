module AssignTagModerator
  def self.add_trusted_role(user)
    return if user.has_role?(:trusted)
    return if user.has_role?(:banned)

    user.add_role :trusted
    user.update(email_community_mod_newsletter: true)
    MailchimpBot.new(user).manage_community_moderator_list
    RedisRailsCache.delete("user-#{user.id}/has_trusted_role")
    NotifyMailer.trusted_role_email(user).deliver
  end

  def self.add_to_chat_channel(user)
    ChatChannel.find_by(slug: "tag-moderators").add_users(user) if user.chat_channels.find_by(slug: "tag-moderators").blank?
  end

  def self.add_tag_mod_role(user, tag)
    user.update(email_tag_mod_newsletter: true) if user.email_tag_mod_newsletter == false
    user.add_role(:tag_moderator, tag)
    Rails.cache.delete("user-#{user.id}/tag_moderators_list")
    MailchimpBot.new(user).manage_tag_moderator_list
  end

  def self.add_tag_moderators(user_ids, tag_ids)
    user_ids.each_with_index do |user_id, index|
      user = User.find(user_id)
      tag = Tag.find(tag_ids[index])
      add_tag_mod_role(user, tag)
      add_trusted_role(user)
      add_to_chat_channel(user)
      NotifyMailer.tag_moderator_confirmation_email(user, tag.name).deliver unless tag.name == "go"
    end
  end

  def self.remove_tag_moderator(user, tag)
    user.remove_role(:tag_moderator, tag)
    user.update(email_tag_mod_newsletter: false) if user.email_tag_mod_newsletter == true
    Rails.cache.delete("user-#{user.id}/tag_moderators_list")
    MailchimpBot.new(user).manage_tag_moderator_list
  end
end
