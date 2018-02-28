class AddFacebookLastBufferedToArticles < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :facebook_last_buffered, :datetime
  end
end
