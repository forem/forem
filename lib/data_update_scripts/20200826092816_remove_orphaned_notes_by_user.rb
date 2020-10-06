module DataUpdateScripts
  class RemoveOrphanedNotesByUser
    def run
      # Delete all Notes about users that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          DELETE FROM notes
          WHERE noteable_type = 'User'
          AND noteable_id NOT IN (SELECT id FROM users);
        SQL
      )
    end
  end
end
