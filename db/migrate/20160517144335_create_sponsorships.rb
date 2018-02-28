class CreateSponsorships < ActiveRecord::Migration
  def change
    create_table :sponsorships do |t|
      t.integer :sponsor_id
      t.integer :sponsorable_id
      t.string  :sponsorable_type
      t.string  :description
      t.timestamps null: false
    end
  end
end
