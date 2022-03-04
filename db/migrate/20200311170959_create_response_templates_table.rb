class CreateResponseTemplatesTable < ActiveRecord::Migration[5.2]
  def change
    create_table :response_templates do |t|
      t.string "type_of", null: false # abuse_report_reply, mod_comment, email_reply, personal_comment
      t.string "content_type", null: false # body_markdown, plain_text, html
      t.text "content", null: false
      t.string "title", null: false
      t.references :user, foreign_key: true # allow null for app wide usage of templates

      t.timestamps null: false
    end

    add_index :response_templates, :type_of
  end
end
