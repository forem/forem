class CreateBroadcasts < ActiveRecord::Migration
  def change
    create_table :broadcasts do |t|
      t.string :title
      t.text :body_markdown
      t.text :processed_html
      t.boolean :sent, default: false
      t.string :type_of
    end

    remove_column :notifications, :body_html, :text
  end
end
