class DropLinksTable < ActiveRecord::Migration[5.1]
  def change
    drop_table :links
  end
end
