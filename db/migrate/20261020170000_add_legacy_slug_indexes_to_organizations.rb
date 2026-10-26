class AddLegacySlugIndexesToOrganizations < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :organizations, :old_slug, algorithm: :concurrently, if_not_exists: true
    add_index :organizations, :old_old_slug, algorithm: :concurrently, if_not_exists: true
  end
end
