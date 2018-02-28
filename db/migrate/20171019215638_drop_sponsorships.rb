class DropSponsorships < ActiveRecord::Migration[5.1]
  def change
    drop_table :sponsorships
  end
end
