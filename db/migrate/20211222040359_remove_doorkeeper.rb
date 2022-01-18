class RemoveDoorkeeper < ActiveRecord::Migration[6.1]
  def up
    drop_table :oauth_access_grants
    drop_table :oauth_access_tokens
    drop_table :oauth_applications, force: :cascade
    drop_table :webhook_endpoints
  end
end
