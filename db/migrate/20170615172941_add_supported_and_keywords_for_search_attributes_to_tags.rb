class AddSupportedAndKeywordsForSearchAttributesToTags < ActiveRecord::Migration
  def change
    add_column :tags, :supported, :boolean, default: false
    add_column :tags, :keywords_for_search, :string
  end
end
