module Github
  # Github client with Application Authentication (uses ocktokit.rb as a backend)
  Client = OauthClient.new(
    client_id: ApplicationConfig["GITHUB_KEY"],
    client_secret: ApplicationConfig["GITHUB_SECRET"],
  )
end
