class AddStatusToReactions < ActiveRecord::Migration[5.1]
  def change
    add_column :reactions, :status, :string, default: "valid"
  end
end
