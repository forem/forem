json.array! @repos.each do |repo|
  json.github_id_code repo.id

  json.extract!(repo, :name, :fork, :selected)
end
