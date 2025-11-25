class UpdateCollectionsUniqueIndexForOrganizationUniqueness < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    # Remove the old unique index that includes user_id
    remove_index :collections,
                 name: "index_collections_on_slug_and_user_id_and_organization_id",
                 algorithm: :concurrently,
                 if_exists: true

    # Add partial unique index for organization collections: slug must be unique within organization_id
    # This enforces that only one series can exist per slug per organization, regardless of user_id
    ActiveRecord::Base.connection.execute(
      <<~SQL
        CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS "index_collections_on_slug_and_organization_id"
        ON "collections"
        USING btree ("slug", "organization_id")
        WHERE "organization_id" IS NOT NULL;
      SQL
    )

    # Add partial unique index for personal collections: slug must be unique within user_id
    # This maintains the existing behavior for personal collections (no organization)
    ActiveRecord::Base.connection.execute(
      <<~SQL
        CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS "index_collections_on_slug_and_user_id"
        ON "collections"
        USING btree ("slug", "user_id")
        WHERE "organization_id" IS NULL;
      SQL
    )
  end

  def down
    # Remove the partial indexes
    ActiveRecord::Base.connection.execute(
      <<~SQL
        DROP INDEX CONCURRENTLY IF EXISTS "index_collections_on_slug_and_organization_id";
      SQL
    )
    ActiveRecord::Base.connection.execute(
      <<~SQL
        DROP INDEX CONCURRENTLY IF EXISTS "index_collections_on_slug_and_user_id";
      SQL
    )

    # Restore the old index
    add_index :collections,
              %i[slug user_id organization_id],
              unique: true,
              name: "index_collections_on_slug_and_user_id_and_organization_id",
              algorithm: :concurrently
  end
end
