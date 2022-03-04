class RemoveUnusedColumnsFromArticles < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_column :articles, :abuse_removal_reason, :string
      remove_column :articles, :allow_big_edits, :boolean, default: true
      remove_column :articles, :allow_small_edits, :boolean, default: true
      remove_column :articles, :amount_due, :float, default: 0.0
      remove_column :articles, :amount_paid, :float, default: 0.0
      remove_column :articles, :automatically_renew, :boolean, default: false
      remove_column :articles, :collection_position, :integer
      remove_column :articles, :featured_clickthrough_rate, :float, default: 0.0
      remove_column :articles, :featured_impressions, :integer, default: 0
      remove_column :articles, :ids_for_suggested_articles, :string, default: "[]"
      remove_column :articles, :job_opportunity_id, :integer
      remove_column :articles, :last_invoiced_at, :datetime
      remove_column :articles, :lat, :decimal, precision: 10, scale: 6
      remove_column :articles, :long, :decimal, precision: 10, scale: 6
      remove_column :articles, :main_tag_name_for_social, :string
      remove_column :articles, :name_within_collection, :string
      remove_column :articles, :paid, :boolean, default: false
      remove_column :articles, :removed_for_abuse, :boolean, default: false
    end
  end
end
