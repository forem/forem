class AddReputationModifierToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :reputation_modifier, :float, default: 1.0
  end
end
