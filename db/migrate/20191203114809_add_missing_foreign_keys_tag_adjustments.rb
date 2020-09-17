class AddMissingForeignKeysTagAdjustments < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key :tag_adjustments, :users, on_delete: :cascade
    add_foreign_key :tag_adjustments, :articles, on_delete: :cascade
    add_foreign_key :tag_adjustments, :tags, on_delete: :cascade
  end
end
