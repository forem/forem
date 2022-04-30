class DropMonthlyDuesFromUsers < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :users, :monthly_dues, :integer, default: 0
    end
  end
end
