class AddTwitchColumnsToUser < ActiveRecord::Migration[5.2]
  def change
    change_table :users do |t|
      t.string :twitch_username, index: true, unique: true
      t.string :currently_streaming_on
    end
  end
end
