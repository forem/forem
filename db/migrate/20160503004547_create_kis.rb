class CreateKis < ActiveRecord::Migration[4.2]
  def change
    create_table :kis do |t|
      t.integer :user_id
      t.text    :body_markdown
      t.string  :body_html
      t.integer  :markdown_character_count, default: 0
      t.boolean :edited, default: false
      t.datetime :edited_at
      t.datetime :published_at
      t.boolean :published, default: false
      t.boolean :featured, default: false
      t.string  :id_code
      t.timestamps null: false
    end
  end
end
