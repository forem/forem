module DataUpdateScripts
  class RemoveDanglingUserReactions
    def run
      # reactions to users who have been deleted should be removed:
      Reaction
        .where(reactable_type: "User")
        .where.not(reactable_id: User.all.select(:id))
        .destroy_all
    end
  end
end
