class AddPatternImageToSponsors < ActiveRecord::Migration
  def change
    add_column :sponsors, :pattern_image, :string
    add_column :sponsors, :subheadline, :string
  end
end
