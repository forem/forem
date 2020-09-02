class AddCachedUserToComments < ActiveRecord::Migration[6.0]
  def change
    add_column :comments, :cached_user, :text
  end
end
