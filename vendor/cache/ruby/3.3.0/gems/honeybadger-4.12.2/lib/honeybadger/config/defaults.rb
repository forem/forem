require 'socket'
require 'honeybadger/breadcrumbs/active_support'

module Honeybadger
  class Config
    class Boolean; end

    IGNORE_DEFAULT = ['ActionController::RoutingError',
                      'AbstractController::ActionNotFound',
                      'ActionController::MethodNotAllowed',
                      'ActionController::UnknownHttpMethod',
                      'ActionController::NotImplemented',
                      'ActionController::UnknownFormat',
                      'ActionController::InvalidAuthenticityToken',
                      'ActionController::InvalidCrossOriginRequest',
                      # ActionDispatch::ParamsParser::ParseError was removed in Rails 6.0
                      # and may be removed here once support for Rails 5.2 is dropped.
                      # https://github.com/rails/rails/commit/e16c765ac6dcff068ff2e5554d69ff345c003de1
                      # https://github.com/honeybadger-io/honeybadger-ruby/pull/358
                      'ActionDispatch::ParamsParser::ParseError',
                      'ActionDispatch::Http::Parameters::ParseError',
                      'ActionController::BadRequest',
                      'ActionController::ParameterMissing',
                      'ActiveRecord::RecordNotFound',
                      'ActionController::UnknownAction',
                      'ActionDispatch::Http::MimeNegotiation::InvalidType',
                      'Rack::QueryParser::ParameterTypeError',
                      'Rack::QueryParser::InvalidParameterError',
                      'CGI::Session::CookieStore::TamperedWithCookie',
                      'Mongoid::Errors::DocumentNotFound',
                      'Sinatra::NotFound'].map(&:freeze).freeze

    DEVELOPMENT_ENVIRONMENTS = ['development', 'test', 'cucumber'].map(&:freeze).freeze

    DEFAULT_PATHS = ['honeybadger.yml', 'config/honeybadger.yml', "#{ENV['HOME']}/honeybadger.yml"].map(&:freeze).freeze

    OPTIONS = {
      api_key: {
        description: 'The API key for your Honeybadger project.',
        default: nil,
        type: String
      },
      env: {
        description: 'The current application\'s environment name.',
        default: nil,
        type: String
      },
      report_data: {
        description: 'Enable/disable reporting of data. Defaults to true for non-development environments.',
        default: nil,
        type: Boolean
      },
      root: {
        description: 'The project\'s absolute root path.',
        default: Dir.pwd,
        type: String
      },
      revision: {
        description: 'The git revision of the project.',
        default: nil,
        type: String
      },
      hostname: {
        description: 'The hostname of the current box.',
        default: Socket.gethostname,
        type: String
      },
      backend: {
        description: 'An alternate backend to use for reporting data.',
        default: nil,
        type: String
      },
      debug: {
        description: 'Enables debug logging.',
        default: false,
        type: Boolean
      },
      development_environments: {
        description: 'Environments which will not report data by default (use report_data to enable/disable explicitly).',
        default: DEVELOPMENT_ENVIRONMENTS,
        type: Array
      },
      :'send_data_at_exit' => {
        description: 'Send remaining data when Ruby exits.',
        default: true,
        type: Boolean
      },
      max_queue_size: {
        description: 'Maximum number of items for each worker queue.',
        default: 100,
        type: Integer
      },
      plugins: {
        description: 'An optional list of plugins to load. Default is to load all plugins.',
        default: nil,
        type: Array
      },
      sync: {
        description: 'Enable all notices to be sent synchronously. Default is false.',
        default: false,
        type: Boolean
      },
      :'skipped_plugins' => {
        description: 'An optional list of plugins to skip.',
        default: nil,
        type: Array
      },
      :'config.path' => {
        description: 'The path (absolute, or relative from config.root) to the project\'s YAML configuration file.',
        default: DEFAULT_PATHS,
        type: String
      },
      :'logging.path' => {
        description: 'The path (absolute, or relative from config.root) to the log file.',
        default: nil,
        type: String
      },
      :'logging.level' => {
        description: 'The log level.',
        default: 'INFO',
        type: String
      },
      :'logging.debug' => {
        description: 'Override debug logging.',
        default: nil,
        type: Boolean
      },
      :'logging.tty_level' => {
        description: 'Level to log when attached to a terminal (anything < logging.level will always be ignored).',
        default: 'DEBUG',
        type: String
      },
      :'connection.secure' => {
        description: 'Use SSL when sending data.',
        default: true,
        type: Boolean
      },
      :'connection.host' => {
        description: 'The host to use when sending data.',
        default: 'api.honeybadger.io'.freeze,
        type: String
      },
      :'connection.port' => {
        description: 'The port to use when sending data.',
        default: nil,
        type: Integer
      },
      :'connection.system_ssl_cert_chain' => {
        description: 'Use the system\'s SSL certificate chain (if available).',
        default: false,
        type: Boolean
      },
      :'connection.ssl_ca_bundle_path' => {
        description: 'Use this ca bundle when establishing secure connections.',
        default: nil,
        type: String
      },
      :'connection.http_open_timeout' => {
        description: 'The HTTP open timeout when connecting to the server.',
        default: 2,
        type: Integer
      },
      :'connection.http_read_timeout' => {
        description: 'The HTTP read timeout when connecting to the server.',
        default: 5,
        type: Integer
      },
      :'connection.proxy_host' => {
        description: 'The proxy host to use when sending data.',
        default: nil,
        type: String
      },
      :'connection.proxy_port' => {
        description: 'The proxy port to use when sending data.',
        default: nil,
        type: Integer
      },
      :'connection.proxy_user' => {
        description: 'The proxy user to use when sending data.',
        default: nil,
        type: String
      },
      :'connection.proxy_pass' => {
        description: 'The proxy password to use when sending data.',
        default: nil,
        type: String
      },
      :'request.filter_keys' => {
        description: 'A list of keys to filter when sending request data.',
        default: ['password'.freeze, 'password_confirmation'.freeze, 'HTTP_AUTHORIZATION'.freeze].freeze,
        type: Array
      },
      :'request.disable_session' => {
        description: 'Prevent session from being sent with request data.',
        default: false,
        type: Boolean
      },
      :'request.disable_params' => {
        description: 'Prevent params from being sent with request data.',
        default: false,
        type: Boolean
      },
      :'request.disable_environment' => {
        description: 'Prevent Rack environment from being sent with request data.',
        default: false,
        type: Boolean
      },
      :'request.disable_url' => {
        description: 'Prevent url from being sent with request data (Rack environment may still contain it in some cases).',
        default: false,
        type: Boolean
      },
      :'user_informer.enabled' => {
        description: 'Enable the UserInformer middleware.',
        default: true,
        type: Boolean
      },
      :'user_informer.info' => {
        description: 'Replacement string for HTML comment in templates.',
        default: 'Honeybadger Error {{error_id}}'.freeze,
        type: String
      },
      :'feedback.enabled' => {
        description: 'Enable the UserFeedback middleware.',
        default: true,
        type: Boolean
      },
      :'exceptions.enabled' => {
        description: 'Enable automatic reporting of exceptions.',
        default: true,
        type: Boolean
      },
      :'exceptions.ignore' => {
        description: 'A list of additional exceptions to ignore (includes default ignored exceptions).',
        default: IGNORE_DEFAULT,
        type: Array
      },
      :'exceptions.ignore_only' => {
        description: 'A list of exceptions to ignore (overrides the default ignored exceptions).',
        default: nil,
        type: Array
      },
      :'exceptions.ignored_user_agents' => {
        description: 'A list of user agents to ignore.',
        default: [].freeze,
        type: Array
      },
      :'exceptions.rescue_rake' => {
        description: 'Enable reporting exceptions in rake tasks.',
        default: !STDOUT.tty?,
        type: Boolean
      },
      :'exceptions.notify_at_exit' => {
        description: 'Report unhandled exception when Ruby crashes (at_exit).',
        default: true,
        type: Boolean
      },
      :'exceptions.source_radius' => {
        description: 'The number of lines before and after the source when reporting snippets.',
        default: 2,
        type: Integer
      },
      :'exceptions.local_variables' => {
        description: 'Enable sending local variables. Requires binding_of_caller to be loaded.',
        default: false,
        type: Boolean
      },
      :'exceptions.unwrap' => {
        description: 'Reports #original_exception or #cause one level up from rescued exception when available.',
        default: false,
        type: Boolean
      },
      :'delayed_job.attempt_threshold' => {
        description: 'The number of attempts before notifications will be sent.',
        default: 0,
        type: Integer
      },
      :'sidekiq.attempt_threshold' => {
        description: 'The number of attempts before notifications will be sent.',
        default: 0,
        type: Integer
      },
      :'shoryuken.attempt_threshold' => {
        description: 'The number of attempts before notifications will be sent.',
        default: 0,
        type: Integer
      },
      :'faktory.attempt_threshold' => {
        description: 'The number of attempts before notifications will be sent.',
        default: 0,
        type: Integer
      },
      :'sidekiq.use_component' => {
        description: 'Automatically set the component to the class of the job. Helps with grouping.',
        default: true,
        type: Boolean
      },
      :'sinatra.enabled' => {
        description: 'Enable Sinatra auto-initialization.',
        default: true,
        type: Boolean
      },
      :'resque.resque_retry.send_exceptions_when_retrying' => {
        description: 'Send exceptions when retrying job.',
        default: true,
        type: Boolean
      },
      :'breadcrumbs.enabled' => {
        description: 'Disable breadcrumb functionality.',
        default: true,
        type: Boolean
      },
      :'breadcrumbs.active_support_notifications' => {
        description: 'Configuration for automatic Active Support Instrumentation events.',
        default: Breadcrumbs::ActiveSupport.default_notifications,
        type: Hash
      },
      :'breadcrumbs.logging.enabled' => {
        description: 'Enable/Disable automatic breadcrumbs from log messages.',
        default: true,
        type: Boolean
      }
    }.freeze

    DEFAULTS = Hash[OPTIONS.map{|k,v| [k, v[:default]] }].freeze
  end
end
