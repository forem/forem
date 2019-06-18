class AddIsTopLevelPathToPages < ActiveRecord::Migration[5.2]
  def change
    add_column :pages, :is_top_level_path, :boolean, default: false
    add_index  :pages, :slug, unique: true
  end
end
