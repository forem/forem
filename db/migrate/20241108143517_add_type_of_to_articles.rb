class AddTypeOfToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :type_of, :integer, default: 0 # enum
  end
end
