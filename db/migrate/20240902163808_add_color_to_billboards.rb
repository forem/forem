class AddColorToBillboards < ActiveRecord::Migration[7.0]
  def change
    add_column :display_ads, :color, :string
  end
end
