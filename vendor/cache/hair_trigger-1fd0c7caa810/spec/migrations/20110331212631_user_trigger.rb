# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class UserTrigger < ActiveRecord::Migration[5.0]
  def up
    create_trigger("users_after_insert_row_when_new_name_bob__tr", :generated => true, :compatibility => 1).
        on("users").
        after(:insert).
        where("NEW.name = 'bob'") do
      "UPDATE user_groups SET bob_count = bob_count + 1"
    end
  end

  def down
    drop_trigger("users_after_insert_row_when_new_name_bob__tr", "users")
  end
end
