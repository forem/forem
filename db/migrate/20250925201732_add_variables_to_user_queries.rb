class AddVariablesToUserQueries < ActiveRecord::Migration[7.0]
  def change
    add_column :user_queries, :variables, :text # JSON string of variable values
    add_column :user_queries, :variable_definitions, :text # JSON string defining expected variables
  end
end
