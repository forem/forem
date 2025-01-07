class AddBrowserContextToBillboards < ActiveRecord::Migration[7.0]
  def change
    add_column :display_ads, :browser_context, :integer, default: 0, null: false
  end
end
