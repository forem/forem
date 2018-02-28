class CreateSponsors < ActiveRecord::Migration
  def change
    create_table :sponsors do |t|
      t.string  :name
      t.text    :description
      t.string  :color_hex
      t.string  :image
      t.timestamps null: false
    end
  end
end
