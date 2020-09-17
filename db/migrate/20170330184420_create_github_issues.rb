class CreateGithubIssues < ActiveRecord::Migration[4.2]
  def change
    create_table :github_issues do |t|
      t.string :url
      t.string :type
      t.string :issue_serialized, default: {}.to_yaml
      t.string :processed_html
      t.timestamps null: false
    end
  end
end
