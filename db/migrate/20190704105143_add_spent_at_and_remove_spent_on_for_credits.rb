class AddSpentAtAndRemoveSpentOnForCredits < ActiveRecord::Migration[5.2]
  def change
    add_column :credits, :spent_at, :datetime
    remove_column :credits, :spent_on, :string
  end
end
