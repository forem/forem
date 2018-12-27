class CreateApiSecrets < ActiveRecord::Migration[5.1]
  def change
    create_table :api_secrets do |t|
      t.string :secret
      t.integer :user_id
      t.string :description, null: false

      t.timestamps
    end
    add_index :api_secrets, :secret, unique: true
    add_index :api_secrets, :user_id
  end
end
