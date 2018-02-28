class AddDescriptionToJobs < ActiveRecord::Migration
  def change
    add_column :job_listings, :description, :string
  end
end
