class CreateDataUpdateScripts < ActiveRecord::Migration[5.2]
  def change
    create_table :data_update_scripts do |t|
      t.string :file_name, unique: true
      t.integer :status, default: 0, null: false
      t.timestamp :run_at
      t.timestamp :finished_at
      t.timestamps null: false
    end
  end
end
