class RemoveUnusedColumnsFromTags < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_column :tags, :submission_rules_headsup, :string
    end
  end
end
