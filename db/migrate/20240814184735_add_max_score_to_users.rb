class AddMaxScoreToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :max_score, :integer, default: 0
  end
end
