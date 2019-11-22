class AddApprovedAndPaidToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :approved, :boolean, default: false
    add_column :articles, :amount_due, :float, default: 0.00
    add_column :articles, :amount_paid, :float, default: 0.00
    add_column :articles, :paid, :boolean, default: false
  end
end
