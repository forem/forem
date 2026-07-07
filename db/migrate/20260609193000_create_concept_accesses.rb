class CreateConceptAccesses < ActiveRecord::Migration[7.0]
  def change
    create_table :concept_accesses do |t|
      t.bigint :user_id, null: false
      t.bigint :concept_id, null: false

      t.timestamps
    end

    add_foreign_key :concept_accesses, :users, on_delete: :cascade, validate: false
    add_foreign_key :concept_accesses, :concepts, on_delete: :cascade, validate: false
  end
end
