class AddPreferOsColorSchemeToUserSettings < ActiveRecord::Migration[6.1]
  def change
    add_column :users_settings, :prefer_os_color_scheme, :boolean, default: true
  end
end
