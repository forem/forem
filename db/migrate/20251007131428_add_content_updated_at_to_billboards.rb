class AddContentUpdatedAtToBillboards < ActiveRecord::Migration[7.0]
  def change
    add_column :display_ads, :content_updated_at, :datetime
  end
end
