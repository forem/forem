class AddOrgPageFeaturesIndexes < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    if index_exists?(:pages, :organization_id)
      remove_index :pages, :organization_id, algorithm: :concurrently
    end

    add_index :pages, :organization_id, algorithm: :concurrently
  end

  def down
    if index_exists?(:pages, :organization_id)
      remove_index :pages, :organization_id, algorithm: :concurrently
    end
  end
end
