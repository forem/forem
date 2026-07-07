class RemoveMlhUsernameFromUsers < ActiveRecord::Migration[7.2]
  # The MLH ↔ Core account link lives on the identities row (provider "mlh",
  # uid = Core user id); this column only ever held the MyMLH OAuth nickname
  # and nothing reads it. Safe to drop directly: User.ignored_columns already
  # excludes it, so no running code references the column when this runs.
  def up
    safety_assured { remove_column :users, :mlh_username }
  end

  def down
    add_column :users, :mlh_username, :string
    add_index :users, :mlh_username, name: :index_users_on_mlh_username
  end
end
