class AddCountsTabulatedAtToBillboards < ActiveRecord::Migration[7.0]
  def change
    add_column :display_ads, :counts_tabulated_at, :datetime
  end
end
