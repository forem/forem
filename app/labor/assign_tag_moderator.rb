module AssignTagModerator
  def self.add_tag_moderators(user_ids, tag_ids)
    user_ids.each_with_index do |user_id, index|
      user = User.find(user_id)
      user.update(email_tag_mod_newsletter: true) if user.email_tag_mod_newsletter == false
      MailchimpBot.new(user).manage_tag_moderator_list
      tag = Tag.find(tag_ids[index])
      user.add_role(:tag_moderator, tag)
      ChatChannel.find_by(slug: "tag-moderators").add_users(user) if user.chat_channels.find_by(slug: "tag-moderators").blank?
      NotifyMailer.tag_moderator_confirmation_email(user, tag.name).deliver unless tag.name == "go"
    end
  end

  def self.remove_tag_moderator(user, tag)
    user.remove_role(:tag_moderator, tag)
    user.update(email_tag_mod_newsletter: false) if user.email_tag_mod_newsletter == true
    MailchimpBot.new(user).manage_tag_moderator_list
  end
end
