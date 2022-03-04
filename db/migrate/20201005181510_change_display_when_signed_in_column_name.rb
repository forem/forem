class ChangeDisplayWhenSignedInColumnName < ActiveRecord::Migration[6.0]
  def change
    safety_assured { rename_column :navigation_links, :display_when_signed_in, :display_only_when_signed_in }
  end
end
