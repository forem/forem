class CreateProfilePins < ActiveRecord::Migration[5.2]
  def change
    create_table :profile_pins do |t|
      t.bigint  :profile_id
      t.bigint  :pinnable_id
      t.string  :profile_type
      t.string  :pinnable_type
      t.timestamps
    end
    add_index("profile_pins", "profile_id")
    add_index("profile_pins", "pinnable_id")
  end
end
