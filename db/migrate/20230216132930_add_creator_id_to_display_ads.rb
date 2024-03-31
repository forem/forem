class AddCreatorIdToDisplayAds < ActiveRecord::Migration[7.0]
  def change
    add_column :display_ads, :creator_id, :integer
  end
end
