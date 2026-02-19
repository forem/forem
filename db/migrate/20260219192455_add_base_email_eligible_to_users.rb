class AddBaseEmailEligibleToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :base_email_eligible, :boolean, default: false, null: false
  end
end
