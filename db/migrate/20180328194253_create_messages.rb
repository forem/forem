class CreateMessages < ActiveRecord::Migration[5.1]
  def change
    create_table :messages do |t|
      t.string :message_html, null: false
      t.string :message_markdown, null: false
      t.references :user, foreign_key: true, null: false
      t.references :chat_channel, foreign_key: true, null: false

      t.timestamps
    end
  end
end
