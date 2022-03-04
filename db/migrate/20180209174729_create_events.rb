class CreateEvents < ActiveRecord::Migration[5.1]
  def change
    create_table :events do |t|
      t.string :title
      t.string :category
      t.datetime :starts_at
      t.datetime :ends_at
      t.string :location_name
      t.string :location_url
      t.string :cover_image
      t.text :description_markdown
      t.text :description_html
      t.boolean :published
      t.timestamps
    end
  end
end
