class CreateLinks < ActiveRecord::Migration
  def change
    create_table :links do |t|
      t.text :title
      t.text :body_html
      t.text :url
      t.text :description
      t.text :image
      t.string :category

      t.timestamps null: false
    end
  end
end
