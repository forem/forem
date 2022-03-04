class AddUniqueIndexToMentionsUserId < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index(
      :mentions,
      %i[user_id mentionable_id mentionable_type],
      unique: true,
      algorithm: :concurrently,
      name: :index_mentions_on_user_id_and_mentionable_id_mentionable_type
    )
  end
end
