class AddPurchaseToCredits < ActiveRecord::Migration[5.2]
  def change
    add_column :credits, :purchase_id, :bigint
    add_column :credits, :purchase_type, :string
    add_index :credits, [:purchase_id, :purchase_type]
  end
end
