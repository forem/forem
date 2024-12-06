# dependencies
require "active_support"
require "browser"
require "ipaddr"

# ext
require "field_test/ext"

# modules
require_relative "field_test/experiment"
require_relative "field_test/helpers"
require_relative "field_test/participant"
require_relative "field_test/version"

# integrations
require_relative "field_test/engine" if defined?(Rails)

module FieldTest
  class Error < StandardError; end
  class ExperimentNotFound < Error; end
  class UnknownParticipant < Error; end

  # same as ahoy
  UUID_NAMESPACE = "a82ae811-5011-45ab-a728-569df7499c5f"

  def self.config_path
    path = defined?(Rails) ? Rails.root : File
    path.join("config", "field_test.yml")
  end

  def self.config
    @config ||= YAML.safe_load(ERB.new(File.read(config_path)).result, permitted_classes: [Date, Time], aliases: true)
  end

  def self.excluded_ips
    @excluded_ips ||= Array(config["exclude"] && config["exclude"]["ips"]).map { |ip| IPAddr.new(ip) }
  end

  def self.exclude_bots?
    config["exclude"] && config["exclude"]["bots"]
  end

  def self.cache
    config["cache"]
  end

  def self.cookies
    config.key?("cookies") ? config["cookies"] : true
  end

  def self.legacy_participants
    config["legacy_participants"]
  end

  def self.precision
    config["precision"] || 0
  end

  def self.events_supported?
    unless defined?(@events_supported)
      connection = FieldTest::Membership.connection
      table_name = "field_test_events"
      @events_supported =
        if connection.respond_to?(:data_source_exists?)
          connection.data_source_exists?(table_name)
        else
          connection.table_exists?(table_name)
        end
    end
    @events_supported
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
end

ActiveSupport.on_load(:action_controller) do
  require "field_test/controller"
  include FieldTest::Controller
end

ActiveSupport.on_load(:action_mailer) do
  require "field_test/mailer"
  include FieldTest::Mailer
end
