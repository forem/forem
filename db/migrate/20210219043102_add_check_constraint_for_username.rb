class AddCheckConstraintForUsername < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      execute(<<~SQL.squish)
        ALTER TABLE "users"
        ADD CONSTRAINT "users_username_not_null"
        CHECK ("username" IS NOT NULL)
        NOT VALID
      SQL
    end
  end
end
