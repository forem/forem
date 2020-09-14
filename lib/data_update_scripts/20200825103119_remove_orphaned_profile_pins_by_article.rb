module DataUpdateScripts
  class RemoveOrphanedProfilePinsByArticle
    def run
      # Delete all ProfilePins belonging to Articles that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          DELETE FROM profile_pins
          WHERE pinnable_type = 'Article'
          AND pinnable_id NOT IN (SELECT id FROM articles);
        SQL
      )
    end
  end
end
