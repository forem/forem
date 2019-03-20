module Notifications
  def self.user_data(user)
    {
      id: user.id,
      class: { name: "User" },
      name: user.name,
      username: user.username,
      path: user.path,
      profile_image_90: user.profile_image_90,
      comments_count: user.comments_count,
      created_at: user.created_at
    }
  end
end
