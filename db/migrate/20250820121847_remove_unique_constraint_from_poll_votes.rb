class RemoveUniqueConstraintFromPollVotes < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    remove_index :poll_votes, name: "index_poll_votes_on_poll_id_and_user_id", algorithm: :concurrently
  end
end
