class CreateClassifiedListingCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :classified_listing_categories do |t|
      t.string :name, null: false, unique: true
      t.integer :cost, null: false
      t.string :rules, null: false

      t.timestamps
    end
  end
end
