# db/migrate/20260713130001_create_email_reengagement_recipients.rb
class CreateEmailReengagementRecipients < ActiveRecord::Migration[7.2]
  def change
    create_table :email_reengagement_recipients do |t|
      t.bigint   :user_id, null: false
      t.string   :campaign_key, null: false
      t.bigint   :email_id
      t.datetime :sent_at
      t.datetime :confirmed_at
      t.datetime :pruned_at
      t.timestamps
    end

    add_index :email_reengagement_recipients, %i[user_id campaign_key],
              unique: true, name: "index_reengagement_recipients_on_user_and_campaign"
    add_index :email_reengagement_recipients, :campaign_key
  end
end
