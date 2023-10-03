class AddBrowserAcceptLanguageToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :browser_accept_language, :string
    add_column :users, :browser_accept_language_updated_at, :datetime
  end
end
