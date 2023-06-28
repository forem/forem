class RemoveBrandColor2FromSettings < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :users_settings, :brand_color2
    end
  end
end
