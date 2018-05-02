class AddEmailDigestEligibleToArticles < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :email_digest_eligible, :boolean, default: true
  end
end
