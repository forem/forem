class ForemInstance
  DEPLOYED_AT = (
    ApplicationConfig["RELEASE_FOOTPRINT"].presence || ENV["HEROKU_RELEASE_CREATED_AT"].presence
  ).freeze

  LATEST_COMMIT_ID = (
    ApplicationConfig["FOREM_BUILD_SHA"].presence || ENV["HEROKU_SLUG_COMMIT"].presence
  ).freeze

  def self.deployed_at
    ApplicationConfig["RELEASE_FOOTPRINT"].presence || ENV["HEROKU_RELEASE_CREATED_AT"].presence
  end

  def self.latest_commit_id
    ApplicationConfig["FOREM_BUILD_SHA"].presence || ENV["HEROKU_SLUG_COMMIT"].presence
  end
end
