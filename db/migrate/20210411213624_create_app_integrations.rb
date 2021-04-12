class CreateAppIntegrations < ActiveRecord::Migration[6.1]
  def change
    create_table :app_integrations do |t|
      t.string :app_bundle, null: false, index: true
      t.string :platform, null: false, index: true
      t.boolean :active, null: false, default: true
      t.string :auth_key
      t.string :last_error
      t.timestamps
    end
  end
end
