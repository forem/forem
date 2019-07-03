class CreatePolls < ActiveRecord::Migration[5.2]
  def change
    create_table :polls do |t|
      t.bigint  :article_id
      t.string  :prompt_markdown
      t.string  :prompt_html
      t.boolean :allow_multiple_selections, default: false
      t.integer :poll_options_count, null: false, default: 0
      t.integer :poll_votes_count, null: false, default: 0
      t.integer :poll_skips_count, null: false, default: 0
      t.timestamps
    end
  end
end
