class CreateNewSponsorships < ActiveRecord::Migration[5.2]
  def change
    create_table :sponsorships do |t|
      t.references :user, foreign_key: true
      t.references :organization, foreign_key: true
      t.string :level, null: false
      t.string :status, null: false, default: "none"
      t.datetime :expires_at
      t.text :blurb_html
      t.integer :featured_number, null: false, default: 0
      t.text :instructions
      t.datetime :instructions_updated_at
      t.string :tagline
      t.string :url
      t.bigint :sponsorable_id
      t.string :sponsorable_type

      t.timestamps
    end
    add_index :sponsorships, :level
    add_index :sponsorships, :status
    add_index :sponsorships, [:sponsorable_id, :sponsorable_type]
  end
end
