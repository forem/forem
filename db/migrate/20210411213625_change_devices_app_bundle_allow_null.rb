class ChangeDevicesAppBundleAllowNull < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    change_column_null :devices, :app_bundle, true
  end
end
