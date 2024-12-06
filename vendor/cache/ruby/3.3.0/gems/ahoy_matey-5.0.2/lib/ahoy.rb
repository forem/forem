# stdlib
require "ipaddr"

# dependencies
require "active_support"
require "active_support/core_ext"
require "safely/core"

# modules
require_relative "ahoy/utils"
require_relative "ahoy/base_store"
require_relative "ahoy/controller"
require_relative "ahoy/database_store"
require_relative "ahoy/helper"
require_relative "ahoy/model"
require_relative "ahoy/query_methods"
require_relative "ahoy/tracker"
require_relative "ahoy/version"
require_relative "ahoy/visit_properties"

require_relative "ahoy/engine" if defined?(Rails)

module Ahoy
  # activejob optional
  autoload :GeocodeV2Job, "ahoy/geocode_v2_job"

  mattr_accessor :visit_duration
  self.visit_duration = 4.hours

  mattr_accessor :visitor_duration
  self.visitor_duration = 2.years

  def self.cookies=(value)
    if value == false
      if defined?(Mongoid::Document) && defined?(Ahoy::Visit) && Ahoy::Visit < Mongoid::Document
        raise <<~EOS
          This feature requires a new index in Ahoy 5. Set:

            class Ahoy::Visit
              index({visitor_token: 1, started_at: 1})
            end

          Create the index before upgrading, and set:

            Ahoy.cookies = :none
        EOS
      else
        raise <<~EOS
          This feature requires a new index in Ahoy 5. Create a migration with:

            add_index :ahoy_visits, [:visitor_token, :started_at]

          Run it before upgrading, and set:

            Ahoy.cookies = :none
        EOS
      end
    end
    @@cookies = value
  end

  mattr_reader :cookies
  self.cookies = true

  # TODO deprecate in favor of cookie_options
  mattr_accessor :cookie_domain

  mattr_accessor :cookie_options
  self.cookie_options = {}

  mattr_accessor :server_side_visits
  self.server_side_visits = true

  mattr_accessor :quiet
  self.quiet = true

  mattr_accessor :geocode
  self.geocode = false

  mattr_accessor :max_content_length
  self.max_content_length = 8192

  mattr_accessor :max_events_per_request
  self.max_events_per_request = 10

  mattr_accessor :job_queue
  self.job_queue = :ahoy

  mattr_accessor :api
  self.api = false

  mattr_accessor :api_only
  self.api_only = false

  mattr_accessor :protect_from_forgery
  self.protect_from_forgery = true

  mattr_accessor :preserve_callbacks
  self.preserve_callbacks = [:load_authlogic, :activate_authlogic]

  mattr_accessor :user_method
  self.user_method = lambda do |controller|
    (controller.respond_to?(:current_user, true) && controller.send(:current_user)) || (controller.respond_to?(:current_resource_owner, true) && controller.send(:current_resource_owner)) || nil
  end

  mattr_accessor :exclude_method

  mattr_accessor :track_bots
  self.track_bots = false

  mattr_accessor :bot_detection_version
  self.bot_detection_version = 2

  mattr_accessor :token_generator
  self.token_generator = -> { SecureRandom.uuid }

  mattr_accessor :mask_ips
  self.mask_ips = false

  mattr_accessor :user_agent_parser
  self.user_agent_parser = :device_detector

  mattr_accessor :logger

  def self.log(message)
    logger.info { "[ahoy] #{message}" } if logger
  end

  def self.cookies?
    cookies && cookies != :none
  end

  def self.mask_ip(ip)
    addr = IPAddr.new(ip)
    if addr.ipv4?
      # set last octet to 0
      addr.mask(24).to_s
    else
      # set last 80 bits to zeros
      addr.mask(48).to_s
    end
  end

  def self.instance
    Thread.current[:ahoy]
  end

  def self.instance=(value)
    Thread.current[:ahoy] = value
  end
end

ActiveSupport.on_load(:action_controller) do
  include Ahoy::Controller
end

ActiveSupport.on_load(:active_record) do
  extend Ahoy::Model
end

ActiveSupport.on_load(:action_view) do
  include Ahoy::Helper
end

ActiveSupport.on_load(:mongoid) do
  Mongoid::Document::ClassMethods.include(Ahoy::Model)
end
