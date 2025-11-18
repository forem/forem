class AddTrendIdToContextNotes < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_reference :context_notes, :trend, null: true, index: {algorithm: :concurrently}
  end
end

