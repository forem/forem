class DropCustomProfileFields < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    drop_table :custom_profile_fields, if_exists: true

    remove_index :custom_profile_fields,
                 column: [:label, :profile_id],
                 algorithm: :concurrently,
                 if_exists: true
  end
end
