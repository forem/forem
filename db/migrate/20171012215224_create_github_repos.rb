class CreateGithubRepos < ActiveRecord::Migration[5.1]
  def change
    create_table :github_repos do |t|
      t.integer :user_id
      t.string :name
      t.string :description
      t.string :language
      t.string :url
      t.integer :bytes_size
      t.integer :watchers_count
      t.integer :stargazers_count
      t.boolean :featured, default: false
      t.integer :priority, default: 0
      t.string :additional_note
      t.text :info_hash, default: [].to_yaml
      t.timestamps
    end
  end
end
