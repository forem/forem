class CreateBadges < ActiveRecord::Migration[5.1]
  def change
    create_table :badges do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.string :description, null: false
      t.string :badge_image

      t.timestamps
    end

    add_index :badges, :title, unique: true
  end
end
