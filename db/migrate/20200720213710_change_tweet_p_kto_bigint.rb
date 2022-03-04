class ChangeTweetPKtoBigint < ActiveRecord::Migration[6.0]
  def up
    safety_assured {
      change_column :tweets, :id, :bigint
    }
  end

  def down
    safety_assured {
      change_column :tweets, :id, :int
    }
  end
end
