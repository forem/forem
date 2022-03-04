class AddPartialIndexesFromComments < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    add_index :comments, :deleted, where: "deleted = false", algorithm: :concurrently unless index_exists?(:comments, :deleted)
    add_index :comments, :hidden_by_commentable_user,where: "hidden_by_commentable_user = false",  algorithm: :concurrently unless index_exists?(:comments, :hidden_by_commentable_user)
  end

  def down
    remove_index :comments, column: :deleted, algorithm: :concurrently if index_exists?(:comments, :deleted)
    remove_index :comments, column: :hidden_by_commentable_user, algorithm: :concurrently if index_exists?(:comments, :hidden_by_commentable_user)
  end
end
