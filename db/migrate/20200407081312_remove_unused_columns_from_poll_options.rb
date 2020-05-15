class RemoveUnusedColumnsFromPollOptions < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_column :poll_options, :counts_in_tabulation, :boolean
    end
  end
end
