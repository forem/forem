class AddDripFieldsToEmails < ActiveRecord::Migration[7.0]
  def change
    add_column :emails, :drip_day, :integer, default: 0
    add_column :emails, :type_of, :integer, default: 0 # enum
    add_column :emails, :status, :integer, default: 0 # enum
  end
end
