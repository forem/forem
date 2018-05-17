class AddRewardingContextMessageToBadges < ActiveRecord::Migration[5.1]
  def change
    add_column :badge_achievements, :rewarding_context_message, :text
  end
end
