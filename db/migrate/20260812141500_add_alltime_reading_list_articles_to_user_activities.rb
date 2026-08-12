class AddAlltimeReadingListArticlesToUserActivities < ActiveRecord::Migration[7.0]
  def change
    add_column :user_activities, :alltime_reading_list_articles, :jsonb, default: []
  end
end
