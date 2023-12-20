class AddArticleIdsToBillboards < ActiveRecord::Migration[7.0]
  def up
    add_column :display_ads, :preferred_article_ids, :integer, array: true, default: []
  end

  def down
    safety_assured { remove_column :display_ads, :preferred_article_ids, :integer, array: true }
  end
end
