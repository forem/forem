class CreateListingEndorsements < ActiveRecord::Migration[6.0]
  def change
    create_table :listing_endorsements do |t|

      t.timestamps
    end
  end
end
