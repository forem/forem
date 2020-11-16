class ChangeMentionsAndNotesPksToBigint < ActiveRecord::Migration[6.0]
  def up
    safety_assured {
      change_column :mentions, :id, :bigint
      change_column :notes, :id, :bigint
    }
  end

  def down
    safety_assured {
      change_column :mentions, :id, :int
      change_column :notes, :id, :int
    }
  end
end
