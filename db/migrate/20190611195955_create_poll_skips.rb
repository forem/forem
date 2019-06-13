class CreatePollSkips < ActiveRecord::Migration[5.2]
  def change
    create_table :poll_skips do |t|
      t.bigint  :user_id
      t.bigint  :poll_id
      t.timestamps
    end
  end
end
