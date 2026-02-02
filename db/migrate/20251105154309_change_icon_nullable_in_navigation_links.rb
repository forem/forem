class ChangeIconNullableInNavigationLinks < ActiveRecord::Migration[7.0]
  def change
    change_column_null :navigation_links, :icon, true
  end
end
