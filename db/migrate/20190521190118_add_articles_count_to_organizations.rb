class AddArticlesCountToOrganizations < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :articles_count, :integer, default: 0, null: false
  end
end
