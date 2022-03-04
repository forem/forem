class AddUniqueIndexToTagAdjustmentsTagName < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :tag_adjustments, %i[tag_name article_id], unique: true, algorithm: :concurrently
  end
end
