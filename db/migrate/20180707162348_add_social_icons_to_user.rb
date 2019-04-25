class AddSocialIconsToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :facebook_url, :string
    add_column :users, :stackoverflow_url, :string
    add_column :users, :linkedin_url, :string
    add_column :users, :behance_url, :string
    add_column :users, :dribbble_url, :string
  end
end
