class CreatePollVotes < ActiveRecord::Migration[5.2]
  def change
    create_table :poll_votes do |t|
      t.bigint  :user_id
      t.bigint  :poll_option_id
      t.timestamps
    end
  end
end
