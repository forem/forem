class AddStripeIdCodeToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :stripe_id_code, :string
  end
end
