class AddLinkedinUrlToProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :profiles, :linkedin_url, :string
  end
end
