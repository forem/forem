class AddOptionalToPolls < ActiveRecord::Migration[7.0]
  def change
    add_column :polls, :optional, :boolean, default: false, null: false
  end
end
