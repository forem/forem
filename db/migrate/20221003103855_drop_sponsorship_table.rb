class DropSponsorshipTable < ActiveRecord::Migration[7.0]
  def up
    safety_assured do
      remove_foreign_key :sponsorships, :organizations
      remove_foreign_key :sponsorships, :users

      drop_table :sponsorships
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigratione
  end
end

