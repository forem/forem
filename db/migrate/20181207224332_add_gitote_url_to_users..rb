class AddGitoteUrlToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :gitote_url, :string
  end
end
