class ForemInstance
  def self.deployed_at
    @deployed_at ||= ApplicationConfig["RELEASE_FOOTPRINT"].presence ||
      ENV["HEROKU_RELEASE_CREATED_AT"].presence ||
      Time.current.to_s
  end

  def self.latest_commit_id
    @latest_commit_id ||= ApplicationConfig["FOREM_BUILD_SHA"].presence || ENV["HEROKU_SLUG_COMMIT"].presence
  end
end
