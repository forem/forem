class AddMarkdownCharacterCountToComments < ActiveRecord::Migration
  def change
    add_column :comments, :markdown_character_count, :integer
  end
end
