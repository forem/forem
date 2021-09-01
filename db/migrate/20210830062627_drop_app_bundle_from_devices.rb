class DropAppBundleFromDevices < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      remove_column :devices, :app_bundle, :string
    end
  end
end
