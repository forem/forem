class ValidateAddTagIdToTrends < ActiveRecord::Migration[7.0]
  def change
    validate_foreign_key :trends, :tags
  end
end
