class AddMiscToSubforems < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :subforems, :misc, :boolean, default: false, null: false
    add_index :subforems, :misc, algorithm: :concurrently
  end
end
