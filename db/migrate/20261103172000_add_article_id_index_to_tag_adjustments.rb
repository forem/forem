class AddArticleIdIndexToTagAdjustments < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :tag_adjustments, :article_id, algorithm: :concurrently, if_not_exists: true
  end
end
