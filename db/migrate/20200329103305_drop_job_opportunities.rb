class DropJobOpportunities < ActiveRecord::Migration[5.2]
  def change
    drop_table :job_opportunities do |t|
      t.string :experience_level
      t.string :location_city
      t.string :location_country_code
      t.string :location_given
      t.decimal :location_lat, precision: 10, scale: 6
      t.decimal :location_long, precision: 10, scale: 6
      t.string :location_postal_code
      t.string :permanency
      t.string :remoteness
      t.string :time_commitment
      t.timestamps
    end
  end
end
