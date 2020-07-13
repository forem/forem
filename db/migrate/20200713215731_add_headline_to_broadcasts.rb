class AddHeadlineToBroadcasts < ActiveRecord::Migration[6.0]
  def change
    add_column :broadcasts, :headline, :string
  end
end
