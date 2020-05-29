class CreatePageRedirect < ActiveRecord::Migration[5.2]
  def change
    create_table :page_redirects do |t|
      t.string :old_path, null: false
      t.string :new_path, null: false
      t.string :source, null: false, default: "service"
      t.integer :version, null: false, default: 0
      t.timestamps null: false
    end

    add_index :page_redirects, :old_path, unique: true
    add_index :page_redirects, :new_path
    add_index :page_redirects, %i[old_path new_path], unique: true
    add_index :page_redirects, :version
    add_index :page_redirects, :source
  end
end
