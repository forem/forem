class RemoveIndexTagAdjustmentsOnTagNameAndArticleId < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    return unless index_exists?(:tag_adjustments, %i[tag_name article_id])

    remove_index :tag_adjustments,
                 column: %i[tag_name article_id],
                 unique: true,
                 algorithm: :concurrently,
                 name: "index_tag_adjustments_on_tag_name_and_article_id"
  end

  def down
    return if index_exists?(:tag_adjustments, %i[tag_name article_id])

    add_index :tag_adjustments, %i[tag_name article_id], unique: true, algorithm: :concurrently
  end
end
