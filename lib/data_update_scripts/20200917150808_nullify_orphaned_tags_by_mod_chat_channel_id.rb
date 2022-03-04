module DataUpdateScripts
  class NullifyOrphanedTagsByModChatChannelId
    def run
      # Nullify all Tags mod_chat_channel_id belonging to ChatChannels that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          UPDATE tags
          SET mod_chat_channel_id = NULL
          WHERE mod_chat_channel_id IS NOT NULL
          AND mod_chat_channel_id NOT IN (SELECT id FROM chat_channels);
        SQL
      )
    end
  end
end
