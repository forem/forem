class CreateCannedResponsesTable < ActiveRecord::Migration[5.2]
  def change
    create_table :canned_responses do |t|
      t.string "type_of", null: false # abuse_report_reply, mod_comment, email, personal_comment
      t.string "content_type", null: false # body_markdown or plain_text or html
      t.text "content", null: false
      t.string "title", null: false
      t.integer "user_id" # nil means belongs to app

      t.timestamps null: false
    end
  end
end
