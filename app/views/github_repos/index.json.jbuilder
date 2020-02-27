json.array! @repos.each do |repo|
  json.github_id_code         repo.id
  json.name                   repo.name
  json.fork                   repo.fork
  json.selected               repo.selected
end
