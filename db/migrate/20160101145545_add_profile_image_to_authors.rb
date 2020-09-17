class AddProfileImageToAuthors < ActiveRecord::Migration[4.2]
  def change
    add_column :authors, :profile_image, :string
  end
end
