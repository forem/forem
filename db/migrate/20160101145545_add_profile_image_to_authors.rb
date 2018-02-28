class AddProfileImageToAuthors < ActiveRecord::Migration
  def change
    add_column :authors, :profile_image, :string
  end
end
