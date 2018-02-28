class AddAliasForToTags < ActiveRecord::Migration
  def change
    add_column :tags, :alias_for, :string
  end
end
