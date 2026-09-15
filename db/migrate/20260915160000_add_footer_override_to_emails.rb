class AddFooterOverrideToEmails < ActiveRecord::Migration[8.0]
  def change
    add_column :emails, :override_footer_html, :boolean, default: false, null: false
    add_column :emails, :custom_footer_html, :text
  end
end
