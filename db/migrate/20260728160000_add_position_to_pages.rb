class AddPositionToPages < ActiveRecord::Migration[8.0]
  def change
    add_column :pages, :position, :integer, default: 0, null: false
  end
end
