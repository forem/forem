class AddSemanticInterestsToArticlesAndUserActivities < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :articles, :semantic_interests, :jsonb, default: {}
    add_index :articles, :semantic_interests, using: :gin, algorithm: :concurrently
    
    add_column :user_activities, :semantic_interest_profile, :jsonb, default: {}
    add_index :user_activities, :semantic_interest_profile, using: :gin, algorithm: :concurrently
  end
end
