class AddNameToAudienceSegments < ActiveRecord::Migration[7.0]
  def change
    add_column :audience_segments, :name, :string
  end
end
