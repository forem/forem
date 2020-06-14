class AddSupportWebmentionsToArticles < ActiveRecord::Migration[6.0]
  def change
    add_column :articles, :support_webmentions, :boolean, default: false
  end
end
