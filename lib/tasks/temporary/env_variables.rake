# Create a .env file from your application.yml file
task create_dot_env_file: :environment do
  exit if File.file?(".env")

  REQUIRED_VALUES = {
    APP_DOMAIN: "localhost:3000",
    APP_PROTOCOL: "http://",
    CLOUDINARY_CLOUD_NAME: "DEV-CLOUD",
    COMMUNITY_COPYRIGHT_START_YEAR: "2016",
    COMMUNITY_NAME: "DEV(local)",
    DEFAULT_EMAIL: "yo@dev.to",
    RACK_TIMEOUT_WAIT_TIMEOUT: 100_000,
    RACK_TIMEOUT_SERVICE_TIMEOUT: 100_000,
    REDIS_URL: "redis://localhost:6379",
    REDIS_SESSIONS_URL: "redis://localhost:6379",
    SESSION_KEY: "_Dev_Community_Session",
    SESSION_EXPIRY_SECONDS: 1209600,
    REDIS_SIDEKIQ_URL: "redis://localhost:6379",
    ELASTICSEARCH_URL: "http://localhost:9200",
  }

  # read existing lines
  application_yml = File.open("config/application.yml", 'r').read


  File.open(".env", "w") do |env_file|
    # add default values only if they are not already present in the
    # application.yml file which would result in a duplicate key
    REQUIRED_VALUES.each_pair do |variable, value|
      env_file.write("export #{variable}=#{value}\n") unless application_yml.include?(variable.to_s)
    end

    File.open("config/application.yml", 'r') do |file|
      file.each_line do |line|
        new_line = line.gsub(": ", "=")
        unless new_line.blank? || new_line.starts_with?("#")
          new_line.prepend("export ")
        end
        env_file.write(new_line)
      end
    end
  end
end
