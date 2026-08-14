class AddRobustMetricsToAiAudits < ActiveRecord::Migration[7.0]
  def change
    add_column :ai_audits, :prompt_token_count, :integer
    add_column :ai_audits, :candidates_token_count, :integer
    add_column :ai_audits, :total_token_count, :integer
    add_column :ai_audits, :latency_ms, :integer
    add_column :ai_audits, :status_code, :integer
    add_column :ai_audits, :error_message, :text
  end
end
