class AddMailchimpListsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :email_tag_mod_newsletter, :boolean, default: false
    add_column :users, :email_community_mod_newsletter, :boolean, default: false
  end
end
