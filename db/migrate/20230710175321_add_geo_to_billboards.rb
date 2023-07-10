class AddGeoToBillboards < ActiveRecord::Migration[7.0]
  def up
    # ?: Should we have a default here? Idk
    add_column :display_ads, :geo_array, :text, array: true
    add_column :display_ads, :geo_text, :text
  end

  def down
    safety_assured do
      remove_column :display_ads, :geo_array
      remove_column :display_ads, :geo_text
    end
  end
end
