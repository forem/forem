class AddFeedReferentialLinkToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :feed_referential_link, :boolean, null: false, default: true
  end
end
