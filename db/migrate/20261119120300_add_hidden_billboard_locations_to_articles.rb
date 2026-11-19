class AddHiddenBillboardLocationsToArticles < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :hidden_billboard_locations, :jsonb, default: [], null: false
  end
end
