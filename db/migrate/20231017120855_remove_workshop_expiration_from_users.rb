class RemoveWorkshopExpirationFromUsers < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :users, :workshop_expiration
    end
  end
end
