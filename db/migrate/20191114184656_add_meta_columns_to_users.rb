class AddMetaColumnsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :last_reaction_at, :datetime, default: "2017-01-01 05:00:00"
    add_column :users, :net_comment_score, :integer, default: 0
    add_column :users, :net_article_score, :integer, default: 0
  end
end
