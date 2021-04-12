class CreateAppIntegrations < ActiveRecord::Migration[6.1]
  def change
    create_table :app_integrations do |t|
      t.string :app_bundle, null: false, index: true
      t.string :platform, null: false, index: true
      t.boolean :active, null: false
      t.string :auth_key
      t.timestamps
    end
  end
end
