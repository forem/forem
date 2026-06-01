class AddTagIdToTrends < ActiveRecord::Migration[7.0]
  def change
    add_column :trends, :tag_id, :bigint
    add_foreign_key :trends, :tags, on_delete: :nullify, validate: false
  end
end
