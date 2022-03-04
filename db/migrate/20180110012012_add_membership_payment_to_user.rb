class AddMembershipPaymentToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :monthly_dues, :integer, default: 0
  end
end
