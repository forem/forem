class AddIdCodeToComments < ActiveRecord::Migration[4.2]
  def change
    add_column :comments, :id_code, :string
  end
end
