module DataUpdateScripts
  class UpdateCachedUserOnComments
    def run
      User.where("comments_count > 0").find_each do |user|
        user.comments.update_all(cached_user: Articles::CachedEntity.from_object(user))
      end
    end
  end
end
