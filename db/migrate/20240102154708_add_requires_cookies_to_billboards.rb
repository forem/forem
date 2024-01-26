class AddRequiresCookiesToBillboards < ActiveRecord::Migration[7.0]
  def change
    add_column :display_ads, :requires_cookies, :boolean, default: false
  end
end
