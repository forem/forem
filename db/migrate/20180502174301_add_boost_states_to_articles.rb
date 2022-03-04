class AddBoostStatesToArticles < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :boost_states, :jsonb, null: false, default: {}
    add_index :articles, :boost_states, using: :gin
  end
end