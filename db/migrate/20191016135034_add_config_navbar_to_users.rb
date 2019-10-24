class AddConfigNavbarToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :config_navbar, :string, default: "default", null: false
  end
end
