module DataUpdateScripts
  class ReplaceInstancesOfBannedAndCommentBanned
    def run
      # Update names for the banned and comment_banned roles
      # Details: https://github.com/forem/forem/pull/11581
      Role.find_by(name: "banned")&.update(name: "suspended")
      Role.find_by(name: "comment_banned")&.update(name: "comment_suspended")
    end
  end
end
