class DropListingEndorsementsTable < ActiveRecord::Migration[6.0]
  def change
    drop_table :classified_listing_endorsements do |t|
      t.string :content
      t.boolean :approved, default: false
      t.references :classified_listing, foreign_key: true
      t.references :user, foreign_key: true
      t.timestamps
    end
  end
end
