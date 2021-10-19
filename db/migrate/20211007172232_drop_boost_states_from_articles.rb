class DropBoostStatesFromArticles < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      remove_column :articles, :boost_states, :jsonb
    end
  end
end
