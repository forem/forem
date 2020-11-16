class ChangeRolePKtoBigint < ActiveRecord::Migration[6.0]
  def up
    safety_assured {
      change_column :roles, :id, :bigint
      change_column :users_roles, :role_id, :bigint
    }
  end

  def down
    safety_assured {
      change_column :roles, :id, :int
      change_column :users_roles, :role_id, :int
    }
  end
end
