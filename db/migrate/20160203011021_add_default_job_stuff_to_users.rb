class AddDefaultJobStuffToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :base_cover_letter, :text
    add_column :users, :resume_html, :text
  end
end
