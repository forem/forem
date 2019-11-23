class AddMarkdownCharacterCountToComments < ActiveRecord::Migration[4.2]
  def change
    add_column :comments, :markdown_character_count, :integer
  end
end
