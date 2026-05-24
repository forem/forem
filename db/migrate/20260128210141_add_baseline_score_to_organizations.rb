class AddBaselineScoreToOrganizations < ActiveRecord::Migration[7.0]
  def change
    add_column :organizations, :baseline_score, :integer, default: 0
  end
end
