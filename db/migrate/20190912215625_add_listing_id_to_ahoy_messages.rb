class AddListingIdToAhoyMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :ahoy_messages, :listing_id, :integer
  end
end
