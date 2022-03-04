class AddScoreToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :score, :integer, default: 0
  end
end
