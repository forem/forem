class AddCoverImageToTrends < ActiveRecord::Migration[7.0]
  def change
    add_column :trends, :cover_image, :string
  end
end
