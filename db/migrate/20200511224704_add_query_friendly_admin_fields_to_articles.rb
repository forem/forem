class AddQueryFriendlyAdminFieldsToArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :query_friendly_title_preamble, :string
    add_column :articles, :query_friendly_description_alternative, :string
  end
end
