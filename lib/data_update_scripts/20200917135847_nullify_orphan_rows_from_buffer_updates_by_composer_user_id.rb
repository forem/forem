module DataUpdateScripts
  class NullifyOrphanRowsFromBufferUpdatesByComposerUserId
    def run
      # Nullify all BufferUpdates composer_user_id belonging to Users that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          UPDATE buffer_updates
          SET composer_user_id = NULL
          WHERE composer_user_id IS NOT NULL
          AND composer_user_id NOT IN (SELECT id FROM users);
        SQL
      )
    end
  end
end
