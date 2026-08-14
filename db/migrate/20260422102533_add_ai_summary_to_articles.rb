class AddAiSummaryToArticles < ActiveRecord::Migration[7.0]
  def up
    add_column :articles, :ai_summary, :text
    add_column :articles, :ai_summary_prompt_version, :string
    add_column :articles, :ai_summary_generated_at, :datetime
  end

  def down
    remove_column :articles, :ai_summary_generated_at
    remove_column :articles, :ai_summary_prompt_version
    remove_column :articles, :ai_summary
  end
end
