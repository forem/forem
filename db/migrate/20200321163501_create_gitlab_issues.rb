class CreateGitlabIssues < ActiveRecord::Migration[5.2]
  def change
    create_table :gitlab_issues do |t|
      t.string :url
      t.string :category
      t.string :issue_serialized, default: {}.to_yaml
      t.string :processed_html
      t.timestamps null: false
    end
  end
end
