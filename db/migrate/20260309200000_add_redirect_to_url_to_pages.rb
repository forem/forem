class AddRedirectToUrlToPages < ActiveRecord::Migration[7.0]
  def change
    add_column :pages, :redirect_to_url, :string
  end
end
