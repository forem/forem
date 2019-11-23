class AddBlockIndexPositionToBlocks < ActiveRecord::Migration[4.2]
  def change
    add_column :blocks, :index_position, :integer
  end
end
