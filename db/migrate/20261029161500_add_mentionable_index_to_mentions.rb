class AddMentionableIndexToMentions < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :mentions,
              %i[mentionable_id mentionable_type],
              name: "index_mentions_on_mentionable_id_and_mentionable_type",
              algorithm: :concurrently
  end
end
