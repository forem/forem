class AddAiDisclosureLevelToArticlesAndComments < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :ai_disclosure_level, :integer, default: 0, null: false
    add_column :comments, :ai_disclosure_level, :integer, default: 0, null: false
  end
end
