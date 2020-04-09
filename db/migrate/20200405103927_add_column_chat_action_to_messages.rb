class AddColumnChatActionToMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :messages, :chat_action, :string
  end
end
