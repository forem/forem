class AddIndexToTagsSocialPreviewTemplate < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :tags, :social_preview_template, algorithm: :concurrently
  end
end
