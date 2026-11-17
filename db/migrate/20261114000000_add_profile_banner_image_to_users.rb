class AddProfileBannerImageToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :profile_banner_image, :string
  end
end
