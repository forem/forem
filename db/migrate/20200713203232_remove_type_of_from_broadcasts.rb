class RemoveTypeOfFromBroadcasts < ActiveRecord::Migration[6.0]
  def change
    safety_assured { remove_column :broadcasts, :type_of, :string }
  end
end
