# Author::   Fastly Inc <support@fastly.com>
# Copyright:: Copyright (c) 2011 Fastly Inc
# License::   Distributes under the same terms as Ruby

# A client library for interacting with the Fastly web acceleration service
require 'fastly/gem_version'
require 'fastly/util'
require 'fastly/fetcher'
require 'fastly/client'
require 'fastly/base'
require 'fastly/belongs_to_service_and_version'
require 'fastly/acl'
require 'fastly/acl_entry'
require 'fastly/backend'
require 'fastly/big_query_logging'
require 'fastly/cache_setting'
require 'fastly/condition'
require 'fastly/customer'
require 'fastly/dictionary'
require 'fastly/dictionary_item'
require 'fastly/director'
require 'fastly/domain'
require 'fastly/header'
require 'fastly/healthcheck'
require 'fastly/gzip'
require 'fastly/invoice'
require 'fastly/match'
require 'fastly/papertrail_logging'
require 'fastly/request_setting'
require 'fastly/response_object'
require 'fastly/service'
require 'fastly/settings'
require 'fastly/snippet'
require 'fastly/dynamic_snippet'
require 'fastly/sumologic_logging'
require 'fastly/syslog'
require 'fastly/token'
require 'fastly/s3_logging'
require 'fastly/gcs_logging'
require 'fastly/user'
require 'fastly/vcl'
require 'fastly/version'

# Top-level Fastly class
class Fastly
  include Fastly::Fetcher

  # Create a new Fastly client. Options are
  #
  # user:: your Fastly login
  # password:: your Fastly password
  # api_key:: your Fastly api key
  #
  # You only need to pass in C<api_key> OR C<user> and C<password>.
  #
  # Some methods require full username and password rather than just auth token.
  def initialize(opts)
    if opts[:api_key].nil?
      raise ArgumentError, "Required option missing. Please pass ':api_key'."
    end

    client(opts)
    self
  end

  # Whether or not we're authed at all by either username & password or API key
  def authed?
    client.authed?
  end

  # Whether or not we're fully (username and password) authed
  # Some methods require full username and password rather than just auth token
  def fully_authed?
    client.fully_authed?
  end

  # Return a Customer object representing the customer of the current logged in user.
  def current_customer
    fail AuthRequired unless authed?
    @current_customer ||= get(Customer)
  end

  # Return a User object representing the current logged in user.
  def current_user
    @current_user ||= get(User)
  end

  # Purge the specified path from your cache.
  def purge(url, soft=false)
    client.purge(url, soft ? { headers: { 'Fastly-Soft-Purge' => "1"} } : {})
  end

  # Fetches historical stats for each of your fastly services and groups the results by service id.
  #
  # If you pass in a :field opt then fetches only the specified field.
  # If you pass in a :service opt then fetches only the specified service.
  # The :field and :service opts can be combined.
  #
  # If you pass in an :aggregate flag then fetches historical stats information aggregated across all of your Fastly services. This cannot be combined with :field and :service.
  #
  # Other options available are:
  #
  # from:: earliest time from which to fetch historical statistics
  # to:: latest time from which to fetch historical statistics
  # by:: the sampling rate used to produce the result set (minute, hour, day)
  # region:: restrict query to a particular region
  #
  # See http://docs.fastly.com/docs/stats for details.
  def stats(opts)
    if opts[:aggregate] && (opts[:field] || opts[:service])
      fail Error, "You can't specify a field or a service for an aggregate request"
    end

    url  = '/stats'

    url += '/aggregate' if opts.delete(:aggregate)

    if service = opts.delete(:service)
      url += "/service/#{service}"
    end

    if field = opts.delete(:field)
      url += "/field/#{field}"
    end

    client.get_stats(url, opts)
  end

  # Returns usage information aggregated across all Fastly services and grouped by region.
  #
  # If the :by_month flag is passed then returns total usage information aggregated by month as well as grouped by service & region.
  #
  # If the :by_service flag is passed then returns usage information aggregated by service and grouped by service & region.
  #
  # Other options available are:
  #
  # from:: earliest time from which to fetch historical statistics
  # to:: latest time from which to fetch historical statistics
  # by:: the sampling rate used to produce the result set (minute, hour, day)
  # region:: restrict query to a particular region
  #
  # See http://docs.fastly.com/docs/stats for details.
  def usage(opts)
    url  = '/stats/usage'
    url += '_by_month' if opts.delete(:by_month)
    url += '_by_service' if opts.delete(:by_service)
    client.get_stats(url, opts)
  end

  # Fetches the list of codes for regions that are covered by the Fastly CDN service.
  def regions
    client.get_stats('/stats/regions')
  end

  [
    ACL,
    ACLEntry,
    Backend,
    CacheSetting,
    Condition,
    Customer,
    Dictionary,
    DictionaryItem,
    Director,
    Domain,
    Gzip,
    Header,
    Healthcheck,
    Match,
    PapertrailLogging,
    RequestSetting,
    ResponseObject,
    S3Logging,
    Service,
    Snippet,
    SumologicLogging,
    Syslog,
    Token,
    User,
    VCL,
    Version,
  ].each do |klass|
    type = Util.class_to_path(klass)

    if klass.respond_to?(:pluralize)
      plural = klass.pluralize
    else
      plural = "#{type}s"
    end

    if klass.respond_to?(:singularize)
      singular = klass.singularize
    else
      singular = type
    end

    # unless the class doesn't have a list path or it already exists
    unless klass.list_path.nil? || klass.respond_to?("list_#{plural}".to_sym)
      send :define_method, "list_#{plural}".to_sym do |*args|
        list(klass, *args)
      end
    end

    send :define_method, "get_#{singular}".to_sym do |*args|
      get(klass, *args)
    end

    send :define_method, "create_#{singular}".to_sym do |obj|
      create(klass, obj)
    end

    send :define_method, "update_#{singular}".to_sym do |obj|
      update(klass, obj)
    end

    send :define_method, "delete_#{singular}".to_sym do |obj|
      delete(klass, obj)
    end
  end

  # :method: create_version(opts)
  # opts must contain a service_id param

  ##
  # :method: create_backend(opts)
  # opts must contain service_id, version and name params

  ##
  # :method: create_dictionary(opts)
  # opts must contain service_id, version and name params

  ##
  # :method: create_dictionary_item(opts)
  # opts must contain service_id, dictionary_id, item_key and item_value params

  ##
  # :method: create_director(opts)
  # opts must contain service_id, version and name params

  ##
  # :method: create_domain(opts)
  # opts must contain service_id, version and name params

  ##
  # :method: create_match(opts)
  # opts must contain service_id, version and name params

  ##
  # :method: create_healthcheck(opts)
  # opts must contain service_id, version and name params

  ##
  # :method: create_s3_logging(opts)
  # opts must contain service_id, version and name params

  ##
  # :method: create_papertrail_logging(opts)
  # opts must contain service_id, version and name params

  ##
  # :method: create_syslog(opts)
  # opts must contain service_id, version and name params

  ##
  # :method: create_vcl(opts)
  # opts must contain service_id, version and name params

  ##
  # :method: create_condition(opts)
  # opts must contain service_id, version and name params

  ##
  # :method: create_cache_setting(opts)
  # opts must contain service_id, version and name params

  ##
  # :method: create_header(opts)
  # opts must contain service_id, version and name params

  ##
  # :method: create_gzip(opts)
  # opts must contain service_id, version and name params

  ##
  # :method: create_request_setting(opts)
  # opts must contain service_id, version and name params

  ##
  # :method: create_response_object(opts)
  # opts must contain service_id, version and name params

  ##
  # :method: get_user(id)
  # Get a User

  ##
  # :method: get_customer(id)
  # Get a customer

  ##
  # :method: get_service(id)
  # Get a Service

  ##
  # :method: get_version(service_id, number)
  # Get a Version

  ##
  # :method: get_backend(service_id, number, name)
  # Get a backend

  ##
  # :method: get_dictionary(service_id, number, name)
  # Get a single dictionary

  ##
  # :method: get_dictionary_item(service_id, dictionary_id, name)
  # Get a single dictionary item

  ##
  # :method: get_director(service_id, number, name)
  # Get a Director

  ##
  # :method: get_domain(service_id, number, name)
  # Get a Domain

  ##
  # :method: get_healthcheck(service_id, number, name)
  # Get a Healthcheck

  ##
  # :method: get_match(service_id, number, name)
  # Get a Match

  ##
  # :method: get_s3_logging(service_id, number, name)
  # Get a S3 logging

  ##
  # :method: get_papertrail_logging(service_id, number, name)
  # Get a Papertrail logging stream config

  ##
  # :method: get_syslog(service_id, number, name)
  # Get a Syslog

  ##
  # :method: get_vcl(service_id, number, name)
  # Get a VCL

  ##
  # :method: get_snippet(service_id, number, name)
  # Get a VCL snippet

  ##
  # :method: get_version(service_id, number, name)
  # Get a Version

  ##
  # :method: get_settings(service_id, number, name)
  # Get a Settings

  ##
  # :method: get_condition(service_id, number, name)
  # Get a Condition

  ##
  # :method: get_cache_setting(service_id, number, name)
  # Get a Cache Setting

  ##
  # :method: get_gzip(service_id, number, name)
  # Get a Gzip

  ##
  # :method: get_header(service_id, number, name)
  # Get a Header

  ##
  # :method: get_request_setting(service_id, number, name)
  # Get a Request Setting

  ##
  # :method: get_response_object(service_id, number, name)
  # Get a Response Object

  ##
  # :method: update_user(user)
  # You can also call
  #    user.save!

  ##
  # :method: update_customer(customer)
  # You can also call
  #    customer.save!

  ##
  # :method: update_service(service)
  # You can also call
  #    service.save!

  ##
  # :method: update_version(version)
  # You can also call
  #    version.save!

  ##
  # :method: update_backend(backend)
  # You can also call
  #    backend.save!

  ##
  # :method: update_dictionary(dictionary)
  # You can also call
  #    dictionary.save!

  ##
  # :method: update_dictionary_item(dictionary_item)
  # You can also call
  #    dictionary_item.save!

  ##
  # :method: update_director(director)
  # You can also call
  #    director.save!

  ##
  # :method: update_domain(domain)
  # You can also call
  #    domain.save!

  ##
  # :method: update_healthcheck(healthcheck)
  # You can also call
  #    healthcheck.save!

  ##
  # :method: update_match(match)
  # You can also call
  #    match.save!

  ##
  # :method: update_settings(settings)
  # You can also call
  #    settings.save!

  ##
  # :method: update_s3_logging(s3_logging)
  # You can also call
  #    s3_logging.save!

  ##
  # :method: update_papertrail_logging(papertrail_logging)
  # You can also call
  #    papertrail_logging.save!

  ##
  # :method: update_syslog(syslog)
  # You can also call
  #    syslog.save!

  ##
  # :method: update_vcl(vcl)
  # You can also call
  #    vcl.save!

  ##
  # :method: update_snippet(snippet)
  # You can also call
  #    snippet.save!

  ##
  # :method: update_cache_setting(cache_setting)
  # You can also call
  #    cache_setting.save!

  ##
  # :method: update_header(header)
  # You can also call
  #    header.save!

  ##
  # :method: update_gzip(gzip)
  # You can also call
  #    gzip.save!

  ##
  # :method: update_request_setting(request_setting)
  # You can also call
  #    request_setting.save!

  ##
  # :method: update_response_object(response_object)
  # You can also call
  #    response_object.save!

  ##
  # :method: update_condition(condition)
  # You can also call
  #    condition.save!

  ##
  # :method: update_version(version)
  # You can also call
  #    version.save!

  ##
  # :method: delete_user(user)
  # You can also call
  #    user.delete!

  ##
  # :method: delete_customer(customer)
  # You can also call
  #    customer.delete!

  ##
  # :method: delete_service(service)
  # You can also call
  #    service.delete!

  ##
  # :method: delete_version(version)
  # You can also call
  #    version.delete!

  ##
  # :method:delete_backend(backend)
  # You can also call
  #    backend.delete!

  ##
  # :method: delete_dictionary(dictionary)
  # You can also call
  #    dictionary.delete!

  ##
  # :method: delete_dictionary_item(dictionary_item)
  # You can also call
  #    dictionary_item.delete!

  ##
  # :method: delete_director(backend)
  # You can also call
  #    backend.delete!

  ##
  # :method: delete_domain(domain
  # You can also call
  #    domain.delete!

  ##
  # :method: delete_healthcheck(healthcheck)
  # You can also call
  #    healthcheck.delete!

  ##
  # :method: delete_match(match)
  # You can also call
  #    match.delete!(match)

  ##
  # :method: delete_s3_logging(s3_logging)
  # You can also call
  #    s3_logging.delete!

  ##
  # :method: delete_papertrail_logging(papertrail_logging)
  # You can also call
  #    papertrail_logging.delete!

  ##
  # :method: delete_syslog(syslog)
  # You can also call
  #    syslog.delete!

  ##
  # :method: delete_vcl(vcl)
  # You can also call
  #    vcl.delete!

  ##
  # :method: delete_snippet(snippet)
  # You can also call
  #    snippet.delete!

  ##
  # :method: delete_cache_setting(cache_setting)
  # You can also call
  #    cache_setting.delete!

  ##
  # :method: delete_header(header)
  # You can also call
  #    header.delete!

  ##
  # :method: delete_gzip(gzip)
  # You can also call
  #    gzip.delete!

  ##
  # :method: delete_request_setting(request_setting)
  # You can also call
  #    request_setting.delete!

  ##
  # :method: delete_response_object(response_object)
  # You can also call
  #    response_object.delete!

  ##
  # :method: delete_condition(condition)
  # You can also call
  #    condition.delete!

  ##
  # :method: delete_version(version)
  # You can also call
  #    version.delete!

  # :method: list_users(:service_id => service.id, :version => version.number)
  #
  # Get a list of all users

  # :method: list_customers(:service_id => service.id, :version => version.number)
  #
  # Get a list of all customers

  # :method: list_versions(:service_id => service.id, :version => version.number)
  #
  # Get a list of all versions

  # :method: list_services(:service_id => service.id, :version => version.number)
  #
  # Get a list of all services

  # :method: list_backends(:service_id => service.id, :version => version.number)
  #
  # Get a list of all backends

  # :method: list_directors(:service_id => service.id, :version => version.number)
  #
  # Get a list of all directors

  # :method: list_dictionaries(:service_id => service.id, :version => version.number)
  #
  # Get a list of all dictionaries

  # :method: list_dictionary_items(:service_id => service.id, :dictionary_id => dictionary.name)
  #
  # Get a list of all items belonging to a dictionary

  # :method: list_domains(:service_id => service.id, :version => version.number)
  #
  # Get a list of all domains

  # :method: list_healthchecks(:service_id => service.id, :version => version.number)
  #
  # Get a list of all healthchecks

  # :method: list_matchs(:service_id => service.id, :version => version.number)
  #
  # Get a list of all matches

  # :method: list_syslogs(:service_id => service.id, :version => version.number)
  #
  # Get a list of all syslogs

  # :method: list_vcls(:service_id => service.id, :version => version.number)
  #
  # Get a list of all vcls

  # :method: list_snippets(:service_id => service.id, :version => version.number)
  #
  # Get a list of all vcl snippets

  # :method: list_conditions(:service_id => service.id, :version => version.number)
  #
  # Get a list of all conditions

  # :method: list_cache_settings(:service_id => service.id, :version => version.number)
  #
  # Get a list of all cache settings

  # :method: list_headers(:service_id => service.id, :version => version.number)
  #
  # Get a list of all headers

  # :method: list_gzips(:service_id => service.id, :version => version.number)
  #
  # Get a list of all gzips

  # :method: list_request_settings(:service_id => service.id, :version => version.number)
  #
  # Get a list of all request_settings

  # :method: list_response_objects(:service_id => service.id, :version => version.number)
  #
  # Get a list of all response_objects

  # :method: list_versions(:service_id => service.id, :version => version.number)
  #
  # Get a list of all versions

  ##
  # Attempts to load various config options in the form
  #
  #    <key> = <value>
  #
  # From a file.
  #
  # Skips whitespace and lines starting with C<#>.
  #
  def self.load_config(file)
    options = {}
    return options unless File.exist?(file)

    File.open(file, 'r') do |infile|
      while line = infile.gets
        line.chomp!
        next if line =~ /^#/
        next if line =~ /^\s*$/
        next unless line =~ /=/
        line.strip!
        key, val = line.split(/\s*=\s*/, 2)
        options[key.to_sym] = val
      end
    end

    options
  end

  ##
  # Tries to load options from the file[s] passed in using,
  # C<load_options>, stopping when it finds the first one.
  #
  # Then it overrides those options with command line options
  # of the form
  #
  #     --<key>=<value>
  #
  def self.get_options(*files)
    options = {}

    files.each do |file|
      next unless File.exist?(file)
      options = load_config(file)
      break
    end

    while ARGV.size > 0 && ARGV[0] =~ /^-+(\w+)\=(\w+)$/
      options[$1.to_sym] = $2
      ARGV.shift
    end

    fail "Couldn't find options from command line arguments or #{files.join(', ')}" unless options.size > 0

    options
  end
end
