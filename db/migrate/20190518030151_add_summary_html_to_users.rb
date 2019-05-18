class AddSummaryHtmlToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :summary_html, :text
  end
end
