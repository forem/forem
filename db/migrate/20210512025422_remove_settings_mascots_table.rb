class RemoveSettingsMascotsTable < ActiveRecord::Migration[6.1]
  def change
    drop_table :settings_mascots
  end
end
