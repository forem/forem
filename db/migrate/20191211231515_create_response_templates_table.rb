class CreateResponseTemplatesTable < ActiveRecord::Migration[5.2]
  def change
    create_table :response_templates do |t|
      t.string "type_of", null: false # abuse_report_reply, mod_comment, email, personal_comment
      t.string "content_type", null: false # body_markdown or plain_text or html
      t.text "content", null: false
      t.string "title", null: false
      t.references :user, foreign_key: true

      t.timestamps null: false
    end
  end
end
