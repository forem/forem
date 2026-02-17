class AddPositionToPolls < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :polls, :position, :integer, default: 0, null: false
    add_index :polls, [:survey_id, :position], name: 'index_polls_on_survey_id_and_position', algorithm: :concurrently
  end
end
