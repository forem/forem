class AddBlockIndexPositionToBlocks < ActiveRecord::Migration
  def change
    add_column :blocks, :index_position, :integer
  end
end
