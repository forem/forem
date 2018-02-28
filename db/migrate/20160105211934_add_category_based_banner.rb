class AddCategoryBasedBanner < ActiveRecord::Migration
  def change
    add_column :articles, :programming_category, :string
  end
end
