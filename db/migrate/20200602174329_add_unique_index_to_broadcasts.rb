class AddUniqueIndexToBroadcasts < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :broadcasts, %i[title type_of], unique: true, algorithm: :concurrently
  end
end
