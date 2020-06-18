class CreatePathRedirect < ActiveRecord::Migration[5.2]
  def change
    create_table :path_redirects do |t|
      t.string :old_path, null: false
      t.string :new_path, null: false
      t.string :source, null: true
      t.integer :version, null: false, default: 0
      t.timestamps null: false
    end

    add_index :path_redirects, :old_path, unique: true
    add_index :path_redirects, :new_path
    add_index :path_redirects, :version
    add_index :path_redirects, :source
  end
end
