class AddLandingPageToPages < ActiveRecord::Migration[6.0]
  def change
    add_column :pages, :landing_page, :boolean, null: false, default: false
  end
end
