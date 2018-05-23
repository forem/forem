class AddLiveColumnsToEvents < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :live_now, :boolean, default: false
    add_column :events, :profile_image, :string
    add_column :events, :host_name, :string
  end
end
