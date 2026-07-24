class ValidateConceptAccessesForeignKeys < ActiveRecord::Migration[7.0]
  def change
    validate_foreign_key :concept_accesses, :users
    validate_foreign_key :concept_accesses, :concepts
  end
end
