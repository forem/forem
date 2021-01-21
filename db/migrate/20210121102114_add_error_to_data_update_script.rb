class AddErrorToDataUpdateScript < ActiveRecord::Migration[6.0]
  def change
    add_column :data_update_scripts, :error, :text
  end
end
