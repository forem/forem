class AddOrganizationIdIndexToArticles < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :articles, :organization_id, algorithm: :concurrently
  end
end
