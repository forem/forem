require 'addressable/uri'

#
# The entry point into Launchy. This is the sole supported public API.
#
#   Launchy.open( uri, options = {} )
#
# The currently defined global options are:
#
#   :debug        Turn on debugging output
#   :application  Explicitly state what application class is going to be used.
#                 This must be a child class of Launchy::Application
#   :host_os      Explicitly state what host operating system to pretend to be
#   :ruby_engine  Explicitly state what ruby engine to pretend to be under
#   :dry_run      Do nothing and print the command that would be executed on $stdout
#
# Other options may be used, and those will be passed directly to the
# application class
#
module Launchy

  class << self
    #
    # Launch an application for the given uri string
    #
    def open(uri_s, options = {}, &error_block )
      leftover = extract_global_options( options )
      uri = string_to_uri( uri_s )
      app = app_for_uri( uri )
      app.new.open( uri, leftover )
    rescue Launchy::Error => le
      raise le
    rescue Exception => e
      msg = "Failure in opening uri #{uri_s.inspect} with options #{options.inspect}: #{e}"
      raise Launchy::Error, msg
    ensure
      if $! and block_given? then
        yield $!
        return # explicitly swallow the errors
      end
    end

    def app_for_uri( uri )
      Launchy::Application.handling( uri )
    end

    def app_for_uri_string( s )
      app_for_uri( string_to_uri( s ) )
    end

    def string_to_uri( s )
      s = s.to_s
      uri = Addressable::URI.parse( s )
      Launchy.log "URI parsing pass 1 : #{s} -> #{uri.to_hash}"
      if not uri.scheme then
        uri = Addressable::URI.heuristic_parse( s )
        Launchy.log "URI parsing pass 2 : #{s} -> #{uri.to_hash}"
      end
      raise Launchy::ArgumentError, "Invalid URI given: #{s.inspect}" unless uri
      return uri
    end

    def reset_global_options
      Launchy.debug       = false
      Launchy.application = nil
      Launchy.host_os     = nil
      Launchy.ruby_engine = nil
      Launchy.dry_run     = false
      Launchy.path        = ENV['PATH']
    end

    def extract_global_options( options )
      leftover = options.dup
      Launchy.debug        = leftover.delete( :debug       ) || ENV['LAUNCHY_DEBUG']
      Launchy.application  = leftover.delete( :application ) || ENV['LAUNCHY_APPLICATION']
      Launchy.host_os      = leftover.delete( :host_os     ) || ENV['LAUNCHY_HOST_OS']
      Launchy.ruby_engine  = leftover.delete( :ruby_engine ) || ENV['LAUNCHY_RUBY_ENGINE']
      Launchy.dry_run      = leftover.delete( :dry_run     ) || ENV['LAUNCHY_DRY_RUN']
    end

    def debug=( d )
      @debug = to_bool( d )
    end

    # we may do logging before a call to 'open', hence the need to check
    # LAUNCHY_DEBUG here
    def debug?
      @debug || to_bool( ENV['LAUNCHY_DEBUG'] )
    end

    def application=( app )
      @application = app
    end

    def application
      @application || ENV['LAUNCHY_APPLICATION']
    end

    def host_os=( host_os )
      @host_os = host_os
    end

    def host_os
      @host_os || ENV['LAUNCHY_HOST_OS']
    end

    def ruby_engine=( ruby_engine )
      @ruby_engine = ruby_engine
    end

    def ruby_engine
      @ruby_engine || ENV['LAUNCHY_RUBY_ENGINE']
    end

    def dry_run=( dry_run )
      @dry_run = to_bool( dry_run )
    end

    def dry_run?
      @dry_run || to_bool( ENV['LAUNCHY_DRY_RUN'] )
    end

    def bug_report_message
      "Please rerun with environment variable LAUNCHY_DEBUG=true or the '-d' commandline option and file a bug at https://github.com/copiousfreetime/launchy/issues/new"
    end

    def log(msg)
      $stderr.puts "LAUNCHY_DEBUG: #{msg}" if Launchy.debug?
    end

    def path
      @path
    end

    def path=(path)
      @path = path
    end

  private
    def to_bool( arg )
      if arg.is_a? String
        arg == 'true'
      elsif arg.is_a? TrueClass
        true
      else
        # All other values mapped to false.
        false
      end
    end
  end

  # Iniitialize the global options to sane defaults during parse time.
  Launchy.reset_global_options
end

require 'launchy/version'
require 'launchy/argv'
require 'launchy/cli'
require 'launchy/descendant_tracker'
require 'launchy/error'
require 'launchy/application'
require 'launchy/detect'
require 'launchy/deprecated'
