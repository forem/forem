class CreateListingEndorsements < ActiveRecord::Migration[6.0]
  def change
    create_table :listing_endorsements do |t|
      t.string :content
      t.boolean :approved
      t.references :classified_listing, foreign_key: true
      t.references :user, foreign_key: true
      t.timestamps
    end
  end
end
