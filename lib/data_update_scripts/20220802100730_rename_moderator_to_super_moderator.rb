module DataUpdateScripts
  class RenameModeratorToSuperModerator
    def run
      Role.where(name: "moderator").update_all(name: "super_moderator")
    end
  end
end
