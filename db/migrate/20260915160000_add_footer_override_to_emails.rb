class AddFooterOverrideToEmails < ActiveRecord::Migration[8.0]
  def change
    change_table :emails, bulk: true do |t|
      t.boolean :override_footer_html, default: false, null: false
      t.text :custom_footer_html
    end
  end
end
