class AddMissingForeignKeysApiSecretsListingsIdentities < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key :api_secrets, :users, on_delete: :cascade
    add_foreign_key :classified_listings, :users, on_delete: :cascade
    add_foreign_key :identities, :users, on_delete: :cascade
  end
end
