class AddBodyMarkdownTsvectorIndexToComments < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  INDEX = "to_tsvector('simple'::regconfig, COALESCE((body_markdown)::text, ''::text))"
  private_constant :INDEX

  INDEX_NAME = "index_comments_on_body_markdown_as_tsvector"
  private_constant :INDEX_NAME

  def up
    return if index_name_exists?(:comments, INDEX_NAME)

    add_index :comments,
              INDEX,
              using: :gin,
              name: INDEX_NAME,
              algorithm: :concurrently
  end

  def down
    return unless index_name_exists?(:comments, INDEX_NAME)

    remove_index :comments,
                 name: INDEX_NAME,
                 algorithm: :concurrently
  end
end
