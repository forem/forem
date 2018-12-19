module AssignTagModerator
  def self.add_tag_moderators(user_ids, tag_names)
    user_ids.each_with_index do |user_id, index|
      user = User.find(user_id)
      tag = Tag.find_by(name: tag_names[index])
      user.add_role(:tag_moderator, tag)
      ChatChannel.find_by_slug("tag_moderators").add_users(user)
      NotifyMailer.tag_moderator_confirmation_email(user, tag.name).deliver unless tag.name == "go"
    end
  end
end
