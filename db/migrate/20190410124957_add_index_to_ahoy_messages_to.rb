class AddIndexToAhoyMessagesTo < ActiveRecord::Migration[5.2]
  def change
    add_index :ahoy_messages, :to
  end
end
