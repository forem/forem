class AddPageIndexToEvents < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :events, :page_id, algorithm: :concurrently
  end
end
