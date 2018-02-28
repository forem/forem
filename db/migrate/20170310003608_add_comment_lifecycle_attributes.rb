class AddCommentLifecycleAttributes < ActiveRecord::Migration
  def change
    add_column :comments, :article_conversion_inquiry, :boolean, default: false
    add_column :comments, :article_conversion_won, :boolean, default: false
    add_column :comments, :article_conversion_lost, :boolean, default: false
  end
end
