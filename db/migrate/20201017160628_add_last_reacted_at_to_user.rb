class AddLastReactedAtToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :last_reacted_at, :datetime
  end
end
