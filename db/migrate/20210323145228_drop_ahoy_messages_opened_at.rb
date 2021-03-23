class DropAhoyMessagesOpenedAt < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      remove_column :ahoy_messages, :opened_at
    end
  end
end
