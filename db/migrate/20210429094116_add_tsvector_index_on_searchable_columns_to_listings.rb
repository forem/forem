class AddTsvectorIndexOnSearchableColumnsToListings < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    return if index_name_exists?(:classified_listings, :index_classified_listings_on_search_fields_as_tsvector)

    query = <<-SQL
    (
      to_tsvector('simple'::regconfig, COALESCE((body_markdown)::text, ''::text)) ||
      to_tsvector('simple'::regconfig, COALESCE((cached_tag_list)::text, ''::text)) ||
      to_tsvector('simple'::regconfig, COALESCE((location)::text, ''::text)) ||
      to_tsvector('simple'::regconfig, COALESCE((slug)::text, ''::text)) ||
      to_tsvector('simple'::regconfig, COALESCE((title)::text, ''::text))
    )
    SQL

    add_index(
      :classified_listings,
      query,
      using: :gin,
      name: :index_classified_listings_on_search_fields_as_tsvector,
      algorithm: :concurrently,
    )
  end

  def down
    return unless index_name_exists?(:classified_listings, :index_classified_listings_on_search_fields_as_tsvector)

    remove_index(
      :classified_listings,
      name: :index_classified_listings_on_search_fields_as_tsvector,
      algorithm: :concurrently,
    )
  end
end
