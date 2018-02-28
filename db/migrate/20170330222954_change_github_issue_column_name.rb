class ChangeGithubIssueColumnName < ActiveRecord::Migration
  def change
    rename_column :github_issues, :type, :category
  end
end
