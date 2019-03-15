class AddConfigToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :config_theme, :string, default: "default"
    add_column :users, :config_font, :string, default: "default"
  end
end
