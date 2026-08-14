class AddScoreUpdatedAtToLinkedDomains < ActiveRecord::Migration[7.0]
  def change
    add_column :linked_domains, :score_updated_at, :datetime
  end
end
