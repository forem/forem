class AddSummaryToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :summary, :text
    add_column :users, :website_url, :string
  end
end
