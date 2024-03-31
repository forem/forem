class RemoveListingsContactViaConnect < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :classified_listings, :contact_via_connect
    end
  end
end
