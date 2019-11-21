class CreateCollection < ActiveRecord::Migration[4.2]
  def change
    create_table :collections do |t|
      t.string  :title
      t.string  :slug
      t.string  :description
      t.string  :main_image
      t.string  :social_image
      t.integer  :user_id
      t.integer :organization_id
      t.boolean :published, default: false
      t.timestamps null: false
    end
    add_index("collections", "user_id")
    add_index("collections", "organization_id")
  end
end
