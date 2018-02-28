class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.integer :author_id
      t.string :title
      t.text :body_html
      t.text :intro_html
      t.text :slug

      t.timestamps null: false
    end
    add_index("articles", "author_id")
  end
end
