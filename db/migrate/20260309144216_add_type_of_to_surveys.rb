class AddTypeOfToSurveys < ActiveRecord::Migration[7.0]
  def change
    add_column :surveys, :type_of, :integer, default: 0, null: false
  end
end
