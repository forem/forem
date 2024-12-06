module Cloudinary
  module Config
    include BaseConfig

    ENV_URL = "CLOUDINARY_URL"
    SCHEME = "cloudinary"

    def load_config_from_env
      if ENV["CLOUDINARY_CLOUD_NAME"]
        config_keys = ENV.keys.select! { |key| key.start_with? "CLOUDINARY_" }
        config_keys -= ["CLOUDINARY_URL"] # ignore it when explicit options are passed
        config_keys.each do |full_key|
          conf_key = full_key["CLOUDINARY_".length..-1].downcase # convert "CLOUDINARY_CONFIG_NAME" to "config_name"
          conf_val = ENV[full_key]
          conf_val = conf_val == 'true' if %w[true false].include?(conf_val) # cast relevant boolean values
          update(conf_key => conf_val)
        end
      elsif ENV[ENV_URL]
        load_from_url(ENV[ENV_URL])
      end
    end

    private

    def env_url
      ENV_URL
    end

    def expected_scheme
      SCHEME
    end

    def config_from_parsed_url(parsed_url)
      {
        "cloud_name"          => parsed_url.host,
        "api_key"             => parsed_url.user,
        "api_secret"          => parsed_url.password,
        "private_cdn"         => !parsed_url.path.blank?,
        "secure_distribution" => parsed_url.path[1..-1]
      }
    end
  end
end
