class AddRemoteAllowedBooleanToJobListings < ActiveRecord::Migration[4.2]
  def change
    add_column :job_listings, :location_status, :string, default: "in office"
  end
end
