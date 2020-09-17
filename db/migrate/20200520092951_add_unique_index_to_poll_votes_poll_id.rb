class AddUniqueIndexToPollVotesPollId < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :poll_votes, %i[poll_id user_id], unique: true, algorithm: :concurrently
  end
end
