class AddCreditsAwardedToBadges < ActiveRecord::Migration[6.0]
  def change
    add_column :badges, :credits_awarded, :integer, default: 0, null: false
  end
end
