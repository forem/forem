class AddUniqueIndexToConceptAccesses < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :concept_accesses, [:user_id, :concept_id], unique: true, algorithm: :concurrently
    add_index :concept_accesses, :concept_id, algorithm: :concurrently
  end
end
