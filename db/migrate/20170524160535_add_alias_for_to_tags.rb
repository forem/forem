class AddAliasForToTags < ActiveRecord::Migration[4.2]
  def change
    add_column :tags, :alias_for, :string
  end
end
