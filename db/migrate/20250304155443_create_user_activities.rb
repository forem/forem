class CreateUserActivities < ActiveRecord::Migration[7.0]
  def change
    create_table :user_activities do |t|
      t.jsonb :recently_viewed_articles, default: []
      t.jsonb :recent_labels, default: []
      t.jsonb :recent_tags, default: []
      t.jsonb :recent_organizations, default: []
      t.jsonb :recent_users, default: []
      t.jsonb :alltime_tags, default: []
      t.jsonb :alltime_labels, default: []
      t.datetime :last_activity_at
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
