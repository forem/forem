class AddLastReactedAtToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :last_reacted_at, :datetime, default: "2017-01-01 05:00:00"
  end
end
