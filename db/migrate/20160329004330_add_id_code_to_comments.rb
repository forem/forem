class AddIdCodeToComments < ActiveRecord::Migration
  def change
    add_column :comments, :id_code, :string
  end
end
