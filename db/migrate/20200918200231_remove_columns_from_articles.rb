class RemoveColumnsFromArticles < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      remove_column :articles, :second_user_id, :bigint
      remove_column :articles, :third_user_id, :bigint
    end
  end
end
