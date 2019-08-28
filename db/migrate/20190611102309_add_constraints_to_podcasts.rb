class AddConstraintsToPodcasts < ActiveRecord::Migration[5.2]
  def up
    change_table :podcasts do |t|
      t.change :main_color_hex, :string, null: false
      t.change :title, :string, null: false
      t.change :image, :string, null: false
      t.change :slug, :string, null: false
      t.change :feed_url, :string, null: false
    end
  end

  def down
    change_table :podcasts do |t|
      t.change :main_color_hex, :string
      t.change :title, :string
      t.change :image, :string
      t.change :slug, :string
      t.change :feed_url, :string
    end
  end
end
