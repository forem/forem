class AddDevicesForeignKeyToAppIntegrations < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :devices, :app_integrations, validate: false
  end
end
