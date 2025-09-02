class AddExpiresAtToBillboards < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :display_ads, :expires_at, :datetime
  end
end
