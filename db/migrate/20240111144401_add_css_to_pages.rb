class AddCssToPages < ActiveRecord::Migration[7.0]
  def change
    add_column :pages, :body_css, :text
  end
end