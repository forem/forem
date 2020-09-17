class RemoveUnusedColumnsFromTweets < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_column :tweets, :primary_external_url, :string
    end
  end
end
