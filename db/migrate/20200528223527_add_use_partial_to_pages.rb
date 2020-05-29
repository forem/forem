class AddUsePartialToPages < ActiveRecord::Migration[5.2]
  def change
    add_column :pages, :use_partial, :boolean, default: false
  end
end
