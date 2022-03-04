class ChangeAuthorIdToUserId < ActiveRecord::Migration[4.2]
  def change
    rename_column :articles, :author_id, :user_id

  end
end
