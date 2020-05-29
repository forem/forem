class AddLocalPathToPages < ActiveRecord::Migration[5.2]
  def change
    add_column :pages, :local_path, :string
  end
end
