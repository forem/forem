class AddCounterCultureToModels < ActiveRecord::Migration
  def change
    add_column :users, :articles_count, :integer, null: false, default: 0
    add_column :users, :comments_count, :integer, null: false, default: 0
    add_column :articles, :comments_count, :integer, null: false, default: 0
    add_column :articles, :reactions_count, :integer, null: false, default: 0
    add_column :comments, :reactions_count, :integer, null: false, default: 0
    add_column :podcast_episodes, :comments_count, :integer, null: false, default: 0
    add_column :podcast_episodes, :reactions_count, :integer, null: false, default: 0
  end
end
