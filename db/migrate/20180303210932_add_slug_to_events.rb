class AddSlugToEvents < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :slug, :string
  end
end
