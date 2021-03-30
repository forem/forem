class AddIndexesToReadingListsView < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    # used to filter by tags
    add_index :reading_lists, :cached_tag_list, using: :gin, opclass: :gin_trgm_ops, algorithm: :concurrently
    # used to FTS search
    add_index :reading_lists, :document, using: :gin, algorithm: :concurrently
    # used to filter by reading list's owner
    add_index :reading_lists, :reaction_user_id, algorithm: :concurrently
    # used to filter by reaction status
    add_index :reading_lists, :reaction_status, algorithm: :concurrently
    # used to concurrently refresh the materialized view
    add_index :reading_lists, %i[path reaction_user_id], unique: true, algorithm: :concurrently
  end
end
