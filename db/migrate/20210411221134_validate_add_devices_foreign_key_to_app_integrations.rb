class ValidateAddDevicesForeignKeyToAppIntegrations < ActiveRecord::Migration[6.1]
  def change
    validate_foreign_key :devices, :consumer_apps
  end
end
