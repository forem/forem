class AddTimestampsToTags < ActiveRecord::Migration[5.1]
  def change
    add_column :tags, :created_at, :datetime
    add_column :tags, :updated_at, :datetime
  end
end
