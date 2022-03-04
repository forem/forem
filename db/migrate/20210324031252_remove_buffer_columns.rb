class RemoveBufferColumns < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      remove_column :articles, :facebook_last_buffered
      remove_column :articles, :last_buffered

      remove_column :classified_listings, :last_buffered

      remove_column :tags, :buffer_profile_id_code
    end
  end
end
