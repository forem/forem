class CreateBadgeCategories < ActiveRecord::Migration[7.0]
  def change
    create_table :badge_categories do |t|
      t.string :name
      t.index :name, unique: true
      t.text :description

      t.timestamps
    end
  end
end
