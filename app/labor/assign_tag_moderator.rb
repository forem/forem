module AssignTagModerator
  def self.add_tag_moderators(user_ids, tag_names)
    user_ids.each_with_index do |user_id, index|
      user = User.find(user_id)
      tag = Tag.find_by(name: tag_names[index])
      user.add_role(:tag_moderator, tag)
    end
  end
end
