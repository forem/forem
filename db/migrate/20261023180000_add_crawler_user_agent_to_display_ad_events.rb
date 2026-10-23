class AddCrawlerUserAgentToDisplayAdEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :display_ad_events, :crawler_user_agent, :boolean
  end
end
