class AddIndexToTagsSocialPreviewTemplate < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    return if index_exists?(:tags, :social_preview_template)

    add_index :tags, :social_preview_template, algorithm: :concurrently
  end

  def down
    return unless index_exists?(:tags, :social_preview_template)

    remove_index :tags, :social_preview_template, algorithm: :concurrently
  end
end
