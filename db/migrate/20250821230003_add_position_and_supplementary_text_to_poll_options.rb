class AddPositionAndSupplementaryTextToPollOptions < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :poll_options, :position, :integer, default: 0, null: false
    add_column :poll_options, :supplementary_text, :string
    add_index :poll_options, [:poll_id, :position], name: 'index_poll_options_on_poll_id_and_position', algorithm: :concurrently
  end
end
