class AddingIndicesToTag < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!
  def change
    add_index :tags, :hotness_score, algorithm: :concurrently
    add_index :tags, :taggings_count, algorithm: :concurrently
  end
end
