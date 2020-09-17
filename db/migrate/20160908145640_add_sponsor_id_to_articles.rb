class AddSponsorIdToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :sponsor_id, :integer
    add_column :articles, :sponsor_showing, :boolean, default: false

  end
end
