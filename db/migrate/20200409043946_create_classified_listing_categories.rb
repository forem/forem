class CreateClassifiedListingCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :classified_listing_categories do |t|
      t.string :name, null: false
      t.integer :cost, null: false
      t.string :rules, null: false
      t.string :slug, null: false

      t.timestamps
    end
    add_index(:classified_listing_categories, :name, unique: true)
    add_index(:classified_listing_categories, :slug, unique: true)
  end
end
