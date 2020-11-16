class CreateNewCommentsBodyMarkdownIndex < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def up
    if index_exists?(
      :comments,
      %i[body_markdown user_id ancestry commentable_id commentable_type],
      name: :index_comments_on_body_markdown_user_id_ancestry_commentable
    )
      remove_index(
        :comments,
        name: :index_comments_on_body_markdown_user_id_ancestry_commentable,
        algorithm: :concurrently
      )
    end

    # needed for the digest() function, checks if the extension already exists
    ActiveRecord::Base.connection.enable_extension("pgcrypto")

    # to avoid the error "Values larger than 1/3 of a buffer page cannot be indexed."
    # due to the fact that large text column cannot be indexed by btree indexes
    # we are going to need to build an index on the hash of the `body_markdown` column.
    # We also cannot use a `HASH` index as it's not supported by unique columns.
    # I don't recommend using GiN or GiST as well
    # See <https://www.postgresql.org/message-id/AANLkTin3p6VS1Z=TtqUV-5cG4TZpTjUMfuPNzWJFgnr5@mail.gmail.com>,
    # <https://www.postgresql.org/docs/11/pgcrypto.html#id-1.11.7.34.5> and
    # <https://www.postgresql.org/docs/11/indexes-types.html>
    ActiveRecord::Base.connection.execute(
      <<~SQL
        CREATE UNIQUE INDEX CONCURRENTLY "index_comments_on_body_markdown_user_ancestry_commentable"
        ON "comments"
        USING btree (digest("body_markdown", 'sha512'::text), "user_id", "ancestry", "commentable_id", "commentable_type");
      SQL
    )
  end

  def down
    ActiveRecord::Base.connection.execute(
      <<~SQL
        DROP INDEX CONCURRENTLY "index_comments_on_body_markdown_user_ancestry_commentable"
      SQL
    )

    unless index_exists?(
      :comments,
      %i[body_markdown user_id ancestry commentable_id commentable_type],
      name: :index_comments_on_body_markdown_user_id_ancestry_commentable
    )
      add_index(
        :comments,
        %i[body_markdown user_id ancestry commentable_id commentable_type],
        unique: true,
        algorithm: :concurrently,
        name: :index_comments_on_body_markdown_user_id_ancestry_commentable
      )
    end
  end
end
