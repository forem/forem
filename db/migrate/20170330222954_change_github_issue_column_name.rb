class ChangeGithubIssueColumnName < ActiveRecord::Migration[4.2]
  def change
    rename_column :github_issues, :type, :category
  end
end
