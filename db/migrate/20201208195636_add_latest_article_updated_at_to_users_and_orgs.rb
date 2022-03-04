class AddLatestArticleUpdatedAtToUsersAndOrgs < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :latest_article_updated_at, :datetime
    add_column :organizations, :latest_article_updated_at, :datetime
  end
end
