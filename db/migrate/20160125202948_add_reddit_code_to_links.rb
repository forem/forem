class AddRedditCodeToLinks < ActiveRecord::Migration[4.2]
  def change
    add_column :links, :reddit_identifier, :string
  end
end
