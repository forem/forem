class RemoveMentorshipColumnsFromUser < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :mentee_description, :text
    remove_column :users, :mentee_form_updated_at, :datetime
    remove_column :users, :mentor_description, :text
    remove_column :users, :mentor_form_updated_at, :datetime
    remove_column :users, :offering_mentorship, :boolean
    remove_column :users, :seeking_mentorship, :boolean
  end
end
