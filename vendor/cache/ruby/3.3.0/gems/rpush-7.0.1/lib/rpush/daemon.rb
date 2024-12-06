# encoding: UTF-8

require 'thread'
require 'socket'
require 'pathname'
require 'openssl'
require 'net/http/persistent'

require 'rpush/daemon/errors'
require 'rpush/daemon/constants'
require 'rpush/daemon/loggable'
require 'rpush/daemon/string_helpers'
require 'rpush/daemon/interruptible_sleep'
require 'rpush/daemon/delivery_error'
require 'rpush/daemon/retryable_error'
require 'rpush/daemon/delivery'
require 'rpush/daemon/feeder'
require 'rpush/daemon/batch'
require 'rpush/daemon/queue_payload'
require 'rpush/daemon/synchronizer'
require 'rpush/daemon/app_runner'
require 'rpush/daemon/tcp_connection'
require 'rpush/daemon/dispatcher_loop'
require 'rpush/daemon/dispatcher/http'
require 'rpush/daemon/dispatcher/tcp'
require 'rpush/daemon/dispatcher/apns_tcp'
require 'rpush/daemon/dispatcher/apns_http2'
require 'rpush/daemon/dispatcher/apnsp8_http2'
require 'rpush/daemon/service_config_methods'
require 'rpush/daemon/retry_header_parser'
require 'rpush/daemon/ring_buffer'
require 'rpush/daemon/signal_handler'
require 'rpush/daemon/proc_title'

require 'rpush/daemon/rpc'
require 'rpush/daemon/rpc/server'
require 'rpush/daemon/rpc/client'

require 'rpush/daemon/store/interface'

require 'rpush/daemon/apns/delivery'
require 'rpush/daemon/apns/feedback_receiver'
require 'rpush/daemon/apns'

require 'rpush/daemon/apns2/delivery'
require 'rpush/daemon/apns2'

require 'rpush/daemon/apnsp8/delivery'
require 'rpush/daemon/apnsp8/token'
require 'rpush/daemon/apnsp8'

require 'rpush/daemon/gcm/delivery'
require 'rpush/daemon/gcm'

require 'rpush/daemon/wpns/delivery'
require 'rpush/daemon/wpns'

require 'rpush/daemon/wns/post_request'
require 'rpush/daemon/wns/raw_request'
require 'rpush/daemon/wns/toast_request'
require 'rpush/daemon/wns/badge_request'
require 'rpush/daemon/wns/delivery'
require 'rpush/daemon/wns'

require 'rpush/daemon/adm/delivery'
require 'rpush/daemon/adm'

require 'rpush/daemon/pushy'
require 'rpush/daemon/pushy/delivery'

require 'rpush/daemon/webpush/delivery'
require 'rpush/daemon/webpush'

module Rpush
  module Daemon
    class << self
      attr_accessor :store
    end

    def self.start
      Process.daemon if daemonize?
      write_pid_file
      SignalHandler.start
      common_init
      Synchronizer.sync
      Rpc::Server.start

      # No further store connections will be made from this thread.
      store.release_connection

      Rpush.logger.info('Rpush operational.')
      show_welcome_if_needed

      # Blocking call, returns after Feeder.stop is called from another thread.
      Feeder.start

      # Wait for shutdown to complete.
      shutdown_lock.synchronize { true }
    end

    def self.shutdown
      if Rpush.config.foreground
        # Eat the '^C'
        STDOUT.write("\b\b")
        STDOUT.flush
      end

      Rpush.logger.info('Shutting down... ', true)

      shutdown_lock.synchronize do
        Rpc::Server.stop
        Feeder.stop
        AppRunner.stop
        delete_pid_file
        puts Rainbow('✔').red if Rpush.config.foreground && Rpush.config.foreground_logging
      end
    end

    def self.shutdown_lock
      @shutdown_lock ||= Mutex.new
    end

    def self.common_init
      init_store
      init_plugins
    end

    protected

    def self.init_store
      return if store
      begin
        name = Rpush.config.client.to_s
        require "rpush/daemon/store/#{name}"
        self.store = Rpush::Daemon::Store.const_get(name.camelcase).new
      rescue StandardError, LoadError => e
        Rpush.logger.error("Failed to load '#{Rpush.config.client}' storage backend.")
        Rpush.logger.error(e)
        exit 1
      end
    end

    def self.init_plugins
      Rpush.plugins.each do |name, plugin|
        plugin.init_block.call
        Rpush.logger.info("[plugin:#{name}] Loaded.")
      end
    end

    def self.daemonize?
      !(Rpush.config.push || Rpush.config.foreground || Rpush.config.embedded || Rpush.jruby?)
    end

    def self.write_pid_file
      unless Rpush.config.pid_file.blank?
        begin
          FileUtils.mkdir_p(File.dirname(Rpush.config.pid_file))
          File.open(Rpush.config.pid_file, 'w') { |f| f.puts Process.pid }
        rescue SystemCallError => e
          Rpush.logger.error("Failed to write PID to '#{Rpush.config.pid_file}': #{e.inspect}")
        end
      end
    end

    def self.delete_pid_file
      pid_file = Rpush.config.pid_file
      File.delete(pid_file) if !pid_file.blank? && File.exist?(pid_file)
    end

    def self.show_welcome_if_needed
      if Rpush::Daemon::AppRunner.app_ids.count == 0
        puts <<-EOS

* #{Rainbow('Is this your first time using Rpush?').green}
  You need to create an App before you can start using Rpush.
  Please refer to the documentation at https://github.com/rpush/rpush

        EOS
      end
    end
  end
end
