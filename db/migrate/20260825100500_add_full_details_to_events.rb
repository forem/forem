class AddFullDetailsToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :full_details, :text
  end
end
