# frozen_string_literal: true

# Standard libraries
require 'socket'
require 'tempfile'
require 'time'
require 'etc'
require 'uri'
require 'stringio'

require 'thread'

# extension files should not be loaded with `require_relative`
require 'puma/puma_http11'
require_relative 'puma/detect'
require_relative 'puma/json_serialization'
require_relative 'rack/version_restriction'

module Puma
  autoload :Const, 'puma/const'
  autoload :Server, 'puma/server'
  autoload :Launcher, 'puma/launcher'

  # at present, MiniSSL::Engine is only defined in extension code (puma_http11),
  # not in minissl.rb
  HAS_SSL = const_defined?(:MiniSSL, false) && MiniSSL.const_defined?(:Engine, false)

  HAS_UNIX_SOCKET = Object.const_defined?(:UNIXSocket) && !IS_WINDOWS

  if HAS_SSL
    require 'puma/minissl'
  else
    module MiniSSL
      # this class is defined so that it exists when Puma is compiled
      # without ssl support, as Server and Reactor use it in rescue statements.
      class SSLError < StandardError ; end
    end
  end

  def self.ssl?
    HAS_SSL
  end

  def self.abstract_unix_socket?
    @abstract_unix ||=
      if HAS_UNIX_SOCKET
        begin
          ::UNIXServer.new("\0puma.temp.unix").close
          true
        rescue ArgumentError  # darwin
          false
        end
      else
        false
      end
  end

  # @!attribute [rw] stats_object=
  def self.stats_object=(val)
    @get_stats = val
  end

  # @!attribute [rw] stats_object
  def self.stats
    Puma::JSONSerialization.generate @get_stats.stats
  end

  # @!attribute [r] stats_hash
  # @version 5.0.0
  def self.stats_hash
    @get_stats.stats
  end

  # Thread name is new in Ruby 2.3
  def self.set_thread_name(name)
    return unless Thread.current.respond_to?(:name=)
    Thread.current.name = "puma #{name}"
  end
end
