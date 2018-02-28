class AddBumpedAtToJobListings < ActiveRecord::Migration
  def change
    add_column :job_listings, :bumped_at, :datetime
  end
end
