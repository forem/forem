class AddUserAgentToDisplayAdEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :display_ad_events, :user_agent, :string
  end
end
