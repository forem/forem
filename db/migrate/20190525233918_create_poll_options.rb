class CreatePollOptions < ActiveRecord::Migration[5.2]
  def change
    create_table :poll_options do |t|
      t.bigint  :poll_id
      t.string  :markdown
      t.string  :processed_html
      t.boolean :counts_in_tabulation
      t.integer :poll_votes_count, null: false, default: 0
      t.timestamps
    end
  end
end
