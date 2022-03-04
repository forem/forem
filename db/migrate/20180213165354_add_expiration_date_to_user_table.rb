class AddExpirationDateToUserTable < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :workshop_expiration, :datetime
  end
end
