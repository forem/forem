module DataUpdateScripts
  class RemoveReactionIndex
    def run
      index_alias = "reactions_#{Rails.env}_alias"
      return unless Search::Client.indices.exists(index: index_alias)

      Search::Client.indices.delete(index: index_alias)
    end
  end
end
