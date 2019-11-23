class AddDescriptionToJobs < ActiveRecord::Migration[4.2]
  def change
    add_column :job_listings, :description, :string
  end
end
