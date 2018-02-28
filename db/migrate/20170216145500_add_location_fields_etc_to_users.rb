class AddLocationFieldsEtcToUsers < ActiveRecord::Migration
  def change
    add_column :users, :top_languages, :string
    add_column :users, :experience_level, :integer
    add_column :users, :specialty, :string
    add_column :users, :tabs_or_spaces, :string
    add_column :users, :shipping_name, :string
    add_column :users, :shipping_company, :string
    add_column :users, :shipping_address, :string
    add_column :users, :shipping_address_line_2, :string
    add_column :users, :shipping_city, :string
    add_column :users, :shipping_state, :string
    add_column :users, :shipping_country, :string
    add_column :users, :shipping_postal_code, :string
    add_column :users, :shirt_gender, :string
    add_column :users, :shirt_size, :string
    add_column :users, :onboarding_package_requested, :boolean, default: false
    add_column :users, :onboarding_package_fulfilled, :boolean, default: false
  end
end
