class ChangeNavigationLinkDefault < ActiveRecord::Migration[6.0]
  def change
    change_column_default(:navigation_links, :requires_auth, false)
  end
end
