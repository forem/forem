class AddRemoteAllowedBooleanToJobListings < ActiveRecord::Migration
  def change
    add_column :job_listings, :location_status, :string, default: "in office"
  end
end
