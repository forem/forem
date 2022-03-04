class AddOauthApplicationIdToWebhookEndpoints < ActiveRecord::Migration[5.2]
  def change
    change_table :webhook_endpoints do |t|
      t.references :oauth_application, foreign_key: true
    end
  end
end
