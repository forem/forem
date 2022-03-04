class CreateDevices < ActiveRecord::Migration[6.0]
  def change
    create_table :devices do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :token, null: false
      t.string :platform, null: false
      t.string :app_bundle, null: false

      t.timestamps
    end

    add_index :devices, [:user_id, :token, :platform, :app_bundle], unique: true
  end
end
