class AddBannerImageToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :banner_image, :string
  end
end
