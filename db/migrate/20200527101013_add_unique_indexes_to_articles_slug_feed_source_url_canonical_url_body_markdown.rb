class AddUniqueIndexesToArticlesSlugFeedSourceUrlCanonicalUrlBodyMarkdown < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    if index_exists?(:articles, :feed_source_url)
      remove_index :articles, column: :feed_source_url, algorithm: :concurrently
    end

    # needed for the digest() function, checks if the extension already exists
    ActiveRecord::Base.connection.enable_extension("pgcrypto")

    add_index :articles, %i[slug user_id], unique: true, algorithm: :concurrently
    add_index :articles, :feed_source_url, unique: true, algorithm: :concurrently
    add_index :articles, :canonical_url, unique: true, algorithm: :concurrently

    # to avoid the error "Values larger than 1/3 of a buffer page cannot be indexed."
    # due to the fact that large text column cannot be indexed by btree indexes
    # we are going to need to build an index on the hash of the `body_markdown` column.
    # We also cannot use a `HASH` index as it's not supported by unique columns.
    # I don't recommend using GiN or GiST as well
    # See <https://www.postgresql.org/message-id/AANLkTin3p6VS1Z=TtqUV-5cG4TZpTjUMfuPNzWJFgnr5@mail.gmail.com>,
    # <https://www.postgresql.org/docs/11/pgcrypto.html#id-1.11.7.34.5> and
    # <https://www.postgresql.org/docs/11/indexes-types.html>
    # NOTE: using SQL as I couldn't find a way to have Rails generate it correctly
    ActiveRecord::Base.connection.execute(
      <<~SQL
        CREATE UNIQUE INDEX CONCURRENTLY "index_articles_on_digest_body_markdown_and_user_id_and_title"
        ON "articles"
        USING btree (digest("body_markdown", 'sha512'::text), "user_id", "title");
      SQL
    )
  end

  def down
    remove_index :articles, column: %i[slug user_id], algorithm: :concurrently
    remove_index :articles, column: :feed_source_url, algorithm: :concurrently
    remove_index :articles, column: :canonical_url, algorithm: :concurrently
    remove_index :articles, name: :index_articles_on_digest_body_markdown_and_user_id_and_title, algorithm: :concurrently
  end
end
