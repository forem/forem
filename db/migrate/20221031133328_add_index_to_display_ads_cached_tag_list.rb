class AddIndexToDisplayAdsCachedTagList < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    # From <https://www.postgresql.org/docs/11/pgtrgm.html#id-1.11.7.40.7>
    # We need a GIN index on `cached_tag_list` to speed up `LIKE` queries
    add_index :display_ads, :cached_tag_list, using: :gin, opclass: :gin_trgm_ops, algorithm: :concurrently, if_not_exists: true
  end
end
