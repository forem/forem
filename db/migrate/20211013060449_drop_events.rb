class DropEvents < ActiveRecord::Migration[6.1]
  def up
    drop_table :events do |t|
      t.string :category
      t.string :cover_image
      t.text :description_html
      t.text :description_markdown
      t.datetime :ends_at
      t.string :host_name
      t.boolean :live_now, default: false
      t.string :location_name
      t.string :location_url
      t.string :profile_image
      t.boolean :published
      t.string :slug
      t.datetime :starts_at
      t.string :title

      t.timestamps
    end
  end
end
