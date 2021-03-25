class AddIndexToTagsSupported < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :tags, :supported, algorithm: :concurrently
  end
end
