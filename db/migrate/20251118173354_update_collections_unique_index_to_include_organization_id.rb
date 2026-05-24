class UpdateCollectionsUniqueIndexToIncludeOrganizationId < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    # Remove the old unique index
    remove_index :collections, name: "index_collections_on_slug_and_user_id", algorithm: :concurrently, if_exists: true

    # Add new unique index that includes organization_id
    # Note: PostgreSQL allows multiple NULLs in unique indexes, but Rails validation
    # will enforce uniqueness at the application level
    add_index :collections, %i[slug user_id organization_id],
              unique: true,
              name: "index_collections_on_slug_and_user_id_and_organization_id",
              algorithm: :concurrently
  end

  def down
    remove_index :collections, name: "index_collections_on_slug_and_user_id_and_organization_id", algorithm: :concurrently, if_exists: true

    add_index :collections, %i[slug user_id],
              unique: true,
              name: "index_collections_on_slug_and_user_id",
              algorithm: :concurrently
  end
end
