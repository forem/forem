class RemoveTwitchColumnsFromUser < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      remove_column :users, :currently_streaming_on
      remove_column :users, :twitch_username
    end
  end
end
