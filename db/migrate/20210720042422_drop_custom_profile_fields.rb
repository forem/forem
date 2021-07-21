class DropCustomProfileFields < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    drop_table :custom_profile_fields, if_exists: true
  end
end
