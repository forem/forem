class AddMentorshipStatusToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :banned_from_mentorship, :boolean
  end
end
