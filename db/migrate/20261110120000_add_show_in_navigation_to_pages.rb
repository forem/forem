class AddShowInNavigationToPages < ActiveRecord::Migration[8.0]
  def change
    add_column :pages, :show_in_navigation, :boolean, default: true, null: false
  end
end
