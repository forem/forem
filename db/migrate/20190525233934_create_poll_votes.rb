class CreatePollVotes < ActiveRecord::Migration[5.2]
  def change
    create_table :poll_votes do |t|
      t.bigint  :user_id
      t.bigint  :poll_option_id
      t.bigint  :poll_option_id
      t.string  :markdown
      t.string  :processed_html
      t.timestamps
    end
  end
end
