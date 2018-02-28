class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.integer :link_id
      t.integer :user_id
      t.text :body_html
      t.boolean :edited, default: false
      t.timestamps null: false
    end
  end
end
