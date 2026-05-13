class SetupVectorColumnsForFeed < ActiveRecord::Migration[7.0]
  def up
    enable_extension "vector"
    safety_assured do
      remove_column :user_activities, :semantic_interest_profile
    end
    add_column :user_activities, :interest_embedding, :vector, limit: 768
    add_column :articles, :semantic_embedding, :vector, limit: 768
  end

  def down
    remove_column :articles, :semantic_embedding
    remove_column :user_activities, :interest_embedding
    add_column :user_activities, :semantic_interest_profile, :jsonb, default: {}
    add_index :user_activities, :semantic_interest_profile, using: :gin
    disable_extension "vector"
  end
end
