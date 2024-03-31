class RemoveUniqueIndexToArticlesUserIdTitleBodyMarkdown < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    remove_index :articles, name: :index_articles_on_user_id_and_title_and_digest_body_markdown, algorithm: :concurrently
  end

  def down
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
        CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS "index_articles_on_user_id_and_title_and_digest_body_markdown"
        ON "articles"
        USING btree ("user_id", "title", digest("body_markdown", 'sha512'::text));
      SQL
    )
  end
end
