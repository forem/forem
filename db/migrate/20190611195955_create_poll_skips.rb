class CreatePollSkips < ActiveRecord::Migration[5.2]
  def change
    create_table :poll_skips do |t|
      t.bigint  :user_id
      t.bigint  :poll_id
      t.timestamps
    end
    add_index :poll_skips, %i[poll_id user_id],
    unique: true,
    name: "index_poll_skips_on_poll_and_user"
  end
end
