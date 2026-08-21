class BackfillUsersOldUsernames < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    User.where.not(old_username: nil).find_each do |user|
      UsersOldUsername.insert(
        { user_id: user.id, username: user.old_username, created_at: Time.current, updated_at: Time.current },
      )
    rescue ActiveRecord::RecordNotUnique
      # skip duplicates
    end

    User.where.not(old_old_username: nil).find_each do |user|
      UsersOldUsername.insert(
        { user_id: user.id, username: user.old_old_username, created_at: Time.current, updated_at: Time.current },
      )
    rescue ActiveRecord::RecordNotUnique
      # skip duplicates
    end
  end

  def down
    UsersOldUsername.delete_all
  end
end
