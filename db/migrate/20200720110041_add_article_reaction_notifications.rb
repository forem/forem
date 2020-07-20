class AddArticleReactionNotifications < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :article_reaction_notifications, :boolean, default: true
  end
end
