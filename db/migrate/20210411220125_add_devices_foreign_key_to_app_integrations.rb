class AddDevicesForeignKeyToAppIntegrations < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :devices, :consumer_apps, validate: false
  end
end
