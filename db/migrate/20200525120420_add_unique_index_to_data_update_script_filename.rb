class AddUniqueIndexToDataUpdateScriptFilename < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :data_update_scripts, :file_name, unique: true, algorithm: :concurrently
  end
end
