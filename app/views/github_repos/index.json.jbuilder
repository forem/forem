json.array! @repos.each do |repo|
  # Repositories pinned in the database (GithubRepo) use their own ID column.
  json.github_id_code repo.is_a?(GithubRepo) ? repo.github_id_code : repo.id

  json.extract!(repo, :name, :fork, :featured)
end
