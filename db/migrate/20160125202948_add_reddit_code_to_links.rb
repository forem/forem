class AddRedditCodeToLinks < ActiveRecord::Migration
  def change
    add_column :links, :reddit_identifier, :string
  end
end
