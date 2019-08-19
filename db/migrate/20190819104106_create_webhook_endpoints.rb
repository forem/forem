class CreateWebhookEndpoints < ActiveRecord::Migration[5.2]
  def change
    create_table :webhook_endpoints do |t|
      t.string :target_url, null: false
      t.string :events, null: false, array: true
      t.references :user, foreign_key: true, null: false
      t.string :source
      t.timestamps
      t.index :events
    end
  end
end
