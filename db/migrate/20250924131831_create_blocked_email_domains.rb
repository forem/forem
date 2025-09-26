class CreateBlockedEmailDomains < ActiveRecord::Migration[7.0]
  def change
    create_table :blocked_email_domains do |t|
      t.string :domain

      t.timestamps
    end
    add_index :blocked_email_domains, :domain, unique: true
  end
end
