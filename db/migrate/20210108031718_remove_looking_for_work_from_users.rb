class RemoveLookingForWorkFromUsers < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      remove_column :users, :looking_for_work
      remove_column :users, :looking_for_work_publicly
    end
  end
end
