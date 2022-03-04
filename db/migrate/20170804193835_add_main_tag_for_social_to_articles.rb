class AddMainTagForSocialToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :main_tag_name_for_social, :string
  end
end
