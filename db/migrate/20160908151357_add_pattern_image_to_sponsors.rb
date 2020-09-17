class AddPatternImageToSponsors < ActiveRecord::Migration[4.2]
  def change
    add_column :sponsors, :pattern_image, :string
    add_column :sponsors, :subheadline, :string
  end
end
