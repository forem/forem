class AddUniqueIndexToGithubIssueUrl < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :github_issues, :url, unique: true, algorithm: :concurrently
  end
end
