class AddSuggestedToTags < ActiveRecord::Migration[7.0]
  def change
    add_column :tags, :suggested, :boolean, default: false
  end
end
