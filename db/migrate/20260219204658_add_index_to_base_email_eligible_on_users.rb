class AddIndexToBaseEmailEligibleOnUsers < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :users, :base_email_eligible, 
              where: "base_email_eligible = true", 
              algorithm: :concurrently
  end
end
