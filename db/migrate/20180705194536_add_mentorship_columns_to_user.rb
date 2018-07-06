class AddMentorshipColumnsToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :offering_mentorship, :boolean
    add_column :users, :seeking_mentorship, :boolean
    add_column :users, :mentor_description, :text
    add_column :users, :mentee_description, :text
  end
end
