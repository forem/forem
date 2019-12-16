class AddCategoryBasedBanner < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :programming_category, :string
  end
end
