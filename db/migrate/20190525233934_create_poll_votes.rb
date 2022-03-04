class CreatePollVotes < ActiveRecord::Migration[5.2]
  def change
    create_table :poll_votes do |t|
      t.bigint  :user_id, null: false
      t.bigint  :poll_id, null: false
      t.bigint  :poll_option_id, null: false
      t.timestamps
    end
    add_index :poll_votes, %i[poll_option_id user_id],
    unique: true,
    name: "index_poll_votes_on_poll_option_and_user"
  end
end
