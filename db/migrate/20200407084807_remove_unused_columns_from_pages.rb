class RemoveUnusedColumnsFromPages < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_column :pages, :group, :string
      remove_column :pages, :group_order_number, :integer
    end
  end
end
