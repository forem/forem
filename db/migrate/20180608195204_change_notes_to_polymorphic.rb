class ChangeNotesToPolymorphic < ActiveRecord::Migration[5.1]
  def change
    rename_column :notes, :user_id, :noteable_id
    add_column :notes, :noteable_type, :string
  end
end
