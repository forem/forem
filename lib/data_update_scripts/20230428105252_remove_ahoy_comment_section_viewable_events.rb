module DataUpdateScripts
  class RemoveAhoyCommentSectionViewableEvents
    def run
      Ahoy::Event.where(name: "Comment section viewable").in_batches.delete_all
    end
  end
end
