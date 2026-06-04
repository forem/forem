class RemoveOrphanedProfilePins < ActiveRecord::Migration[7.0]
  def up
    ProfilePin.where(pinnable_type: "Article").where("NOT EXISTS (SELECT 1 FROM articles WHERE articles.id = profile_pins.pinnable_id)").delete_all
  end

  def down
    # Irreversible migration
  end
end
