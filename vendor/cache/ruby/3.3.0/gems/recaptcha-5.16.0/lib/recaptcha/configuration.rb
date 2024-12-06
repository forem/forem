# frozen_string_literal: true

module Recaptcha
  # This class enables detailed configuration of the recaptcha services.
  #
  # By calling
  #
  #   Recaptcha.configuration # => instance of Recaptcha::Configuration
  #
  # or
  #   Recaptcha.configure do |config|
  #     config # => instance of Recaptcha::Configuration
  #   end
  #
  # you are able to perform configuration updates.
  #
  # Your are able to customize all attributes listed below. All values have
  # sensitive default and will very likely not need to be changed.
  #
  # Please note that the site and secret key for the reCAPTCHA API Access
  # have no useful default value. The keys may be set via the Shell enviroment
  # or using this configuration. Settings within this configuration always take
  # precedence.
  #
  # Setting the keys with this Configuration
  #
  #   Recaptcha.configure do |config|
  #     config.site_key  = '6Lc6BAAAAAAAAChqRbQZcn_yyyyyyyyyyyyyyyyy'
  #     config.secret_key = '6Lc6BAAAAAAAAKN3DRm6VA_xxxxxxxxxxxxxxxxx'
  #   end
  #
  class Configuration
    DEFAULTS = {
      'free_server_url' => 'https://www.recaptcha.net/recaptcha/api.js',
      'enterprise_server_url' => 'https://www.recaptcha.net/recaptcha/enterprise.js',
      'free_verify_url' => 'https://www.recaptcha.net/recaptcha/api/siteverify',
      'enterprise_verify_url' => 'https://recaptchaenterprise.googleapis.com/v1/projects'
    }.freeze

    attr_accessor :default_env, :skip_verify_env, :proxy, :secret_key, :site_key, :handle_timeouts_gracefully,
                  :hostname, :enterprise, :enterprise_api_key, :enterprise_project_id, :response_limit
    attr_writer :api_server_url, :verify_url

    def initialize # :nodoc:
      @default_env = ENV['RAILS_ENV'] || ENV['RACK_ENV'] || (Rails.env if defined? Rails.env)
      @skip_verify_env = %w[test cucumber]
      @handle_timeouts_gracefully = true

      @secret_key = ENV['RECAPTCHA_SECRET_KEY']
      @site_key = ENV['RECAPTCHA_SITE_KEY']

      @enterprise = ENV['RECAPTCHA_ENTERPRISE'] == 'true'
      @enterprise_api_key = ENV['RECAPTCHA_ENTERPRISE_API_KEY']
      @enterprise_project_id = ENV['RECAPTCHA_ENTERPRISE_PROJECT_ID']

      @verify_url = nil
      @api_server_url = nil

      @response_limit = 4000
    end

    def secret_key!
      secret_key || raise(RecaptchaError, "No secret key specified.")
    end

    def site_key!
      site_key || raise(RecaptchaError, "No site key specified.")
    end

    def enterprise_api_key!
      enterprise_api_key || raise(RecaptchaError, "No Enterprise API key specified.")
    end

    def enterprise_project_id!
      enterprise_project_id || raise(RecaptchaError, "No Enterprise project ID specified.")
    end

    def api_server_url
      @api_server_url || (enterprise ? DEFAULTS.fetch('enterprise_server_url') : DEFAULTS.fetch('free_server_url'))
    end

    def verify_url
      @verify_url || (enterprise ? DEFAULTS.fetch('enterprise_verify_url') : DEFAULTS.fetch('free_verify_url'))
    end
  end
end
