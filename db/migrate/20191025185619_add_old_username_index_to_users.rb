class AddOldUsernameIndexToUsers < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    if indexes(:users).none? { |idx| idx.columns.map(&:to_sym) == [:old_username] }
      add_index :users, :old_username, algorithm: :concurrently
    end

    if indexes(:users).none? { |idx| idx.columns.map(&:to_sym) == [:old_old_username] }
      add_index :users, :old_old_username, algorithm: :concurrently
    end
  end

  def down
    if indexes(:users).any? { |idx| idx.columns.map(&:to_sym) == [:old_username] }
      remove_index :users, :old_username
    end

    if indexes(:users).any? { |idx| idx.columns.map(&:to_sym) == [:old_old_username] }
      remove_index :users, :old_old_username
    end
  end
end
