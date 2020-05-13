class RemoveUnusedColumnsFromPolls < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_column :polls, :allow_multiple_selections, :boolean, default: false
    end
  end
end
