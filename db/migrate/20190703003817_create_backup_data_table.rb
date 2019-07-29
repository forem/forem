class CreateBackupDataTable < ActiveRecord::Migration[5.2]
  def change
    create_table :backup_data do |t|
      t.bigint :instance_id, null: false
      t.string :instance_type, null: false
      t.bigint :instance_user_id
      t.jsonb :json_data, null: false

      t.timestamps null: false
    end
  end
end
