# dependencies
require "active_support"
require "addressable/uri"
require "nokogiri"
require "safely/core"

# stdlib
require "openssl"

# modules
require_relative "ahoy_email/processor"
require_relative "ahoy_email/tracker"
require_relative "ahoy_email/observer"
require_relative "ahoy_email/mailer"
require_relative "ahoy_email/utils"
require_relative "ahoy_email/version"

# subscribers
require_relative "ahoy_email/database_subscriber"
require_relative "ahoy_email/message_subscriber"
require_relative "ahoy_email/redis_subscriber"

# integrations
require_relative "ahoy_email/engine" if defined?(Rails)

module AhoyEmail
  mattr_accessor :secret_token, :default_options, :subscribers, :invalid_redirect_url, :track_method, :api, :preserve_callbacks, :save_token
  mattr_writer :message_model

  self.api = false

  self.default_options = {
    # message history
    message: false,
    user: -> { (defined?(@user) && @user) || (respond_to?(:params) && params && params[:user]) || (message.to.try(:size) == 1 ? (User.find_by(email: message.to.first) rescue nil) : nil) },
    mailer: -> { "#{self.class.name}##{action_name}" },
    extra: {},

    # utm params
    utm_params: false,
    utm_source: -> { mailer_name },
    utm_medium: "email",
    utm_term: nil,
    utm_content: nil,
    utm_campaign: -> { action_name },

    # click analytics
    click: false,
    campaign: nil,
    url_options: {},
    unsubscribe_links: false,

    # utm params and click analytics
    html5: nil
  }

  self.track_method = lambda do |data|
    message = data[:message]

    ahoy_message = AhoyEmail.message_model.new
    ahoy_message.to = Array(message.to).join(", ") if ahoy_message.respond_to?(:to=)
    ahoy_message.user = data[:user] if ahoy_message.respond_to?(:user=)

    ahoy_message.mailer = data[:mailer] if ahoy_message.respond_to?(:mailer=)
    ahoy_message.subject = message.subject if ahoy_message.respond_to?(:subject=)
    ahoy_message.content = message.encoded if ahoy_message.respond_to?(:content=)

    AhoyEmail::Processor::UTM_PARAMETERS.each do |k|
      ahoy_message.send("#{k}=", data[k.to_sym]) if ahoy_message.respond_to?("#{k}=")
    end

    ahoy_message.token = data[:token] if ahoy_message.respond_to?(:token=)
    ahoy_message.campaign = data[:campaign] if ahoy_message.respond_to?(:campaign=)

    ahoy_message.assign_attributes(data[:extra] || {})

    ahoy_message.sent_at = Time.now
    ahoy_message.save!

    ahoy_message
  end

  self.save_token = false

  self.subscribers = []

  self.preserve_callbacks = []

  self.message_model = -> { ::Ahoy::Message }

  def self.message_model
    model = defined?(@@message_model) && @@message_model
    model = model.call if model.respond_to?(:call)
    model
  end

  # shortcut for first subscriber with stats method
  def self.stats(*args)
    subscriber = subscribers.find { |s| s.is_a?(Class) ? s.method_defined?(:stats) : s.respond_to?(:stats) }
    subscriber = subscriber.new if subscriber.is_a?(Class)
    subscriber.stats(*args) if subscriber
  end
end

ActiveSupport.on_load(:action_mailer) do
  include AhoyEmail::Mailer
  register_observer AhoyEmail::Observer
  Mail::Message.send(:attr_accessor, :ahoy_data, :ahoy_message, :ahoy_options)
end
