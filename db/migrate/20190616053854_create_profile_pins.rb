class CreateProfilePins < ActiveRecord::Migration[5.2]
  def change
    create_table :profile_pins do |t|
      t.bigint  :profile_id
      t.bigint  :pinnable_id
      t.string  :profile_type
      t.string  :pinnable_type
      t.timestamps
    end
  end
end
