class AddPriorityToDisplayAds < ActiveRecord::Migration[7.0]
  def change
    add_column :display_ads, :priority, :boolean, default: false
  end
end
