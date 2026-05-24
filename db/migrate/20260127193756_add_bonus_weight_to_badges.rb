class AddBonusWeightToBadges < ActiveRecord::Migration[7.0]
  def change
    add_column :badges, :bonus_weight, :integer, default: 0
  end
end
