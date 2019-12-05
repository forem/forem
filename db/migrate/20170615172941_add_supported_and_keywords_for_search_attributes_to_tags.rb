class AddSupportedAndKeywordsForSearchAttributesToTags < ActiveRecord::Migration[4.2]
  def change
    add_column :tags, :supported, :boolean, default: false
    add_column :tags, :keywords_for_search, :string
  end
end
