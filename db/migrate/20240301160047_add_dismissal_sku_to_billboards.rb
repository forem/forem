class AddDismissalSkuToBillboards < ActiveRecord::Migration[7.0]
  def change
    add_column :display_ads, :dismissal_sku, :string
  end
end
