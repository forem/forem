class AddAudienceSegmentToDisplayAds < ActiveRecord::Migration[7.0]
  def change
    add_column :display_ads, :audience_segment_id, :integer
  end
end
