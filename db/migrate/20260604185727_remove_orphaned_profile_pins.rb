class RemoveOrphanedProfilePins < ActiveRecord::Migration[7.0]
  def up
    execute(<<~SQL)
      DELETE FROM profile_pins
      WHERE pinnable_type = 'Article'
        AND NOT EXISTS (
          SELECT 1 FROM articles
          WHERE articles.id = profile_pins.pinnable_id
        )
    SQL
  end

  def down
    # Irreversible migration
  end
end
