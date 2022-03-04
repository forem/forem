class AddJobOpportunityIdToArticles < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :job_opportunity_id, :integer
  end
end
