class AddRootToSubforems < ActiveRecord::Migration[7.0]
  def change
    add_column :subforems, :root, :boolean, default: false
  end
end
