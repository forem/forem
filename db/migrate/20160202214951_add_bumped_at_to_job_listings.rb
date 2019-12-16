class AddBumpedAtToJobListings < ActiveRecord::Migration[4.2]
  def change
    add_column :job_listings, :bumped_at, :datetime
  end
end
