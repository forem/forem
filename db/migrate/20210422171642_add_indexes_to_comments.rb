class AddIndexesToComments < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    add_index :comments, :commentable_type, algorithm: :concurrently unless index_exists?(:comments, :commentable_type)
    add_index :comments, :deleted, algorithm: :concurrently unless index_exists?(:comments, :deleted)
    add_index :comments, :hidden_by_commentable_user, algorithm: :concurrently unless index_exists?(:comments, :hidden_by_commentable_user)
  end

  def down
    remove_index :comments, column: :commentable_type, algorithm: :concurrently if index_exists?(:comments, :commentable_type)
    remove_index :comments, column: :deleted, algorithm: :concurrently if index_exists?(:comments, :deleted)
    remove_index :comments, column: :hidden_by_commentable_user, algorithm: :concurrently if index_exists?(:comments, :hidden_by_commentable_user)
  end
end
