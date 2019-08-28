class AddIndexesForAnalytics < ActiveRecord::Migration[5.2]
  # transactions are disabled to allow PostgreSQL to add indexes concurrently
  disable_ddl_transaction!

  def change
    # concurrent creation avoids downtime during production deploy because
    # indexes get created in the background
    add_index :articles, :published, algorithm: :concurrently
    add_index :comments, :created_at, algorithm: :concurrently
    add_index :comments, :score, algorithm: :concurrently
    add_index :follows, :created_at, algorithm: :concurrently
    add_index :page_views, :created_at, algorithm: :concurrently
    add_index :reactions, :created_at, algorithm: :concurrently
    add_index :reactions, :points, algorithm: :concurrently
  end
end
