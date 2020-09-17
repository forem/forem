class AddQueryFriendlyAdminFieldsToArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :search_optimized_title_preamble, :string
    add_column :articles, :search_optimized_description_replacement, :string
  end
end
