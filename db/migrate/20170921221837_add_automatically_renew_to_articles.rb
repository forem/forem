class AddAutomaticallyRenewToArticles < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :automatically_renew, :boolean, default: false
    add_column :articles, :last_invoiced_at, :datetime
  end
end
