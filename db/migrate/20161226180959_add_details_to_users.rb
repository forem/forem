class AddDetailsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :employer_name, :string
    add_column :users, :employer_url, :string
    add_column :users, :employment_title, :string
    add_column :users, :currently_learning, :string
    add_column :users, :mostly_work_with, :string
    add_column :users, :available_for, :string
    add_column :users, :currently_hacking_on, :string
    add_column :users, :location, :string
    add_column :users, :email_public, :boolean, default: false
    add_column :users, :education, :string
  end
end
