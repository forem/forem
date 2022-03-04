class CreateConsumerApps < ActiveRecord::Migration[6.1]
  def change
    create_table :consumer_apps do |t|
      t.string :app_bundle, null: false
      t.string :platform, null: false
      t.boolean :active, null: false, default: true
      t.string :auth_key
      t.string :last_error
      t.timestamps
    end

    add_index :consumer_apps, [:app_bundle, :platform], unique: true
  end
end
