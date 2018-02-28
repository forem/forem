class CreateJobOpportunities < ActiveRecord::Migration[5.1]
  def change
    create_table :job_opportunities do |t|
      t.string :remoteness
      t.string :experience_level
      t.string :time_commitment
      t.string :permanency
      t.string :location_given
      t.string :location_city
      t.string :location_country_code
      t.string :location_postal_code
      t.decimal :location_lat, precision: 10, scale: 6
      t.decimal :location_long, precision: 10, scale: 6
    # add_column :articles, :location_given, :string
    # add_column :articles, :location_city, :string
    # add_column :articles, :location_country_code, :string
    # add_column :articles, :location_postal_code, :string
    #     add_column :articles, :lat, :decimal, precision: 10, scale: 6
    # add_column :articles, :long, :decimal, precision: 10, scale: 6

      # t.integer :number_of_employees
      # t.float   :cost_per_click, default: 0
      # t.integer :impressions_count, default: 0
      # t.integer :clicks_count, default: 0
      # t.boolean :published, default: false
      # t.boolean :approved, default: false
      t.timestamps
    end
  end
end
