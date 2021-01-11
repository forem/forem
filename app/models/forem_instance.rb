class ForemInstance
  def self.deployed_at
    ApplicationConfig["RELEASE_FOOTPRINT"].presence || ENV["HEROKU_RELEASE_CREATED_AT"].presence || "Not Available"
  end

  def self.latest_commit_id
    ApplicationConfig["FOREM_BUILD_SHA"].presence || ENV["HEROKU_SLUG_COMMIT"].presence || "Not Available"
  end
end
