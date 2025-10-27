class AddVariablesToEmails < ActiveRecord::Migration[7.0]
  def change
    add_column :emails, :variables, :text
  end
end
