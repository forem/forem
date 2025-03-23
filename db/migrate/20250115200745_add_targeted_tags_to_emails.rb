class AddTargetedTagsToEmails < ActiveRecord::Migration[7.0]
  def change
    add_column :emails, :targeted_tags, :string, array: true, default: []
  end
end
