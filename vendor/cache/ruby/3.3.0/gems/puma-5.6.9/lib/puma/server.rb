# frozen_string_literal: true

require 'stringio'

require 'puma/thread_pool'
require 'puma/const'
require 'puma/events'
require 'puma/null_io'
require 'puma/reactor'
require 'puma/client'
require 'puma/binder'
require 'puma/util'
require 'puma/io_buffer'
require 'puma/request'

require 'socket'
require 'io/wait'
require 'forwardable'

module Puma

  # The HTTP Server itself. Serves out a single Rack app.
  #
  # This class is used by the `Puma::Single` and `Puma::Cluster` classes
  # to generate one or more `Puma::Server` instances capable of handling requests.
  # Each Puma process will contain one `Puma::Server` instance.
  #
  # The `Puma::Server` instance pulls requests from the socket, adds them to a
  # `Puma::Reactor` where they get eventually passed to a `Puma::ThreadPool`.
  #
  # Each `Puma::Server` will have one reactor and one thread pool.
  class Server

    include Puma::Const
    include Request
    extend Forwardable

    attr_reader :thread
    attr_reader :events
    attr_reader :min_threads, :max_threads  # for #stats
    attr_reader :requests_count             # @version 5.0.0
    attr_reader :log_writer                 # to help with backports

    # @todo the following may be deprecated in the future
    attr_reader :auto_trim_time, :early_hints, :first_data_timeout,
      :leak_stack_on_error,
      :persistent_timeout, :reaping_time

    # @deprecated v6.0.0
    attr_writer :auto_trim_time, :early_hints, :first_data_timeout,
      :leak_stack_on_error, :min_threads, :max_threads,
      :persistent_timeout, :reaping_time

    attr_accessor :app
    attr_accessor :binder

    def_delegators :@binder, :add_tcp_listener, :add_ssl_listener,
      :add_unix_listener, :connected_ports

    ThreadLocalKey = :puma_server

    # Create a server for the rack app +app+.
    #
    # +events+ is an object which will be called when certain error events occur
    # to be handled. See Puma::Events for the list of current methods to implement.
    #
    # Server#run returns a thread that you can join on to wait for the server
    # to do its work.
    #
    # @note Several instance variables exist so they are available for testing,
    #   and have default values set via +fetch+.  Normally the values are set via
    #   `::Puma::Configuration.puma_default_options`.
    #
    def initialize(app, events=Events.stdio, options={})
      @app = app
      @events = events
      @log_writer = events

      @check, @notify = nil
      @status = :stop

      @auto_trim_time = 30
      @reaping_time = 1

      @thread = nil
      @thread_pool = nil

      @options = options

      @early_hints         = options.fetch :early_hints, nil
      @first_data_timeout  = options.fetch :first_data_timeout, FIRST_DATA_TIMEOUT
      @min_threads         = options.fetch :min_threads, 0
      @max_threads         = options.fetch :max_threads , (Puma.mri? ? 5 : 16)
      @persistent_timeout  = options.fetch :persistent_timeout, PERSISTENT_TIMEOUT
      @queue_requests      = options.fetch :queue_requests, true
      @max_fast_inline     = options.fetch :max_fast_inline, MAX_FAST_INLINE
      @io_selector_backend = options.fetch :io_selector_backend, :auto

      temp = !!(@options[:environment] =~ /\A(development|test)\z/)
      @leak_stack_on_error = @options[:environment] ? temp : true

      @binder = Binder.new(events)

      ENV['RACK_ENV'] ||= "development"

      @mode = :http

      @precheck_closing = true

      @requests_count = 0
    end

    def inherit_binder(bind)
      @binder = bind
    end

    class << self
      # @!attribute [r] current
      def current
        Thread.current[ThreadLocalKey]
      end

      # :nodoc:
      # @version 5.0.0
      def tcp_cork_supported?
        Socket.const_defined?(:TCP_CORK) && Socket.const_defined?(:IPPROTO_TCP)
      end

      # :nodoc:
      # @version 5.0.0
      def closed_socket_supported?
        Socket.const_defined?(:TCP_INFO) && Socket.const_defined?(:IPPROTO_TCP)
      end
      private :tcp_cork_supported?
      private :closed_socket_supported?
    end

    # On Linux, use TCP_CORK to better control how the TCP stack
    # packetizes our stream. This improves both latency and throughput.
    # socket parameter may be an MiniSSL::Socket, so use to_io
    #
    if tcp_cork_supported?
      # 6 == Socket::IPPROTO_TCP
      # 3 == TCP_CORK
      # 1/0 == turn on/off
      def cork_socket(socket)
        skt = socket.to_io
        begin
          skt.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_CORK, 1) if skt.kind_of? TCPSocket
        rescue IOError, SystemCallError
          Puma::Util.purge_interrupt_queue
        end
      end

      def uncork_socket(socket)
        skt = socket.to_io
        begin
          skt.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_CORK, 0) if skt.kind_of? TCPSocket
        rescue IOError, SystemCallError
          Puma::Util.purge_interrupt_queue
        end
      end
    else
      def cork_socket(socket)
      end

      def uncork_socket(socket)
      end
    end

    if closed_socket_supported?
      UNPACK_TCP_STATE_FROM_TCP_INFO = "C".freeze

      def closed_socket?(socket)
        skt = socket.to_io
        return false unless skt.kind_of?(TCPSocket) && @precheck_closing

        begin
          tcp_info = skt.getsockopt(Socket::IPPROTO_TCP, Socket::TCP_INFO)
        rescue IOError, SystemCallError
          Puma::Util.purge_interrupt_queue
          @precheck_closing = false
          false
        else
          state = tcp_info.unpack(UNPACK_TCP_STATE_FROM_TCP_INFO)[0]
          # TIME_WAIT: 6, CLOSE: 7, CLOSE_WAIT: 8, LAST_ACK: 9, CLOSING: 11
          (state >= 6 && state <= 9) || state == 11
        end
      end
    else
      def closed_socket?(socket)
        false
      end
    end

    # @!attribute [r] backlog
    def backlog
      @thread_pool and @thread_pool.backlog
    end

    # @!attribute [r] running
    def running
      @thread_pool and @thread_pool.spawned
    end


    # This number represents the number of requests that
    # the server is capable of taking right now.
    #
    # For example if the number is 5 then it means
    # there are 5 threads sitting idle ready to take
    # a request. If one request comes in, then the
    # value would be 4 until it finishes processing.
    # @!attribute [r] pool_capacity
    def pool_capacity
      @thread_pool and @thread_pool.pool_capacity
    end

    # Runs the server.
    #
    # If +background+ is true (the default) then a thread is spun
    # up in the background to handle requests. Otherwise requests
    # are handled synchronously.
    #
    def run(background=true, thread_name: 'srv')
      BasicSocket.do_not_reverse_lookup = true

      @events.fire :state, :booting

      @status = :run

      @thread_pool = ThreadPool.new(
        thread_name,
        @min_threads,
        @max_threads,
        ::Puma::IOBuffer,
        &method(:process_client)
      )

      @thread_pool.out_of_band_hook = @options[:out_of_band]
      @thread_pool.clean_thread_locals = @options[:clean_thread_locals]

      if @queue_requests
        @reactor = Reactor.new(@io_selector_backend, &method(:reactor_wakeup))
        @reactor.run
      end

      if @reaping_time
        @thread_pool.auto_reap!(@reaping_time)
      end

      if @auto_trim_time
        @thread_pool.auto_trim!(@auto_trim_time)
      end

      @check, @notify = Puma::Util.pipe unless @notify

      @events.fire :state, :running

      if background
        @thread = Thread.new do
          Puma.set_thread_name thread_name
          handle_servers
        end
        return @thread
      else
        handle_servers
      end
    end

    # This method is called from the Reactor thread when a queued Client receives data,
    # times out, or when the Reactor is shutting down.
    #
    # It is responsible for ensuring that a request has been completely received
    # before it starts to be processed by the ThreadPool. This may be known as read buffering.
    # If read buffering is not done, and no other read buffering is performed (such as by an application server
    # such as nginx) then the application would be subject to a slow client attack.
    #
    # For a graphical representation of how the request buffer works see [architecture.md](https://github.com/puma/puma/blob/master/docs/architecture.md#connection-pipeline).
    #
    # The method checks to see if it has the full header and body with
    # the `Puma::Client#try_to_finish` method. If the full request has been sent,
    # then the request is passed to the ThreadPool (`@thread_pool << client`)
    # so that a "worker thread" can pick up the request and begin to execute application logic.
    # The Client is then removed from the reactor (return `true`).
    #
    # If a client object times out, a 408 response is written, its connection is closed,
    # and the object is removed from the reactor (return `true`).
    #
    # If the Reactor is shutting down, all Clients are either timed out or passed to the
    # ThreadPool, depending on their current state (#can_close?).
    #
    # Otherwise, if the full request is not ready then the client will remain in the reactor
    # (return `false`). When the client sends more data to the socket the `Puma::Client` object
    # will wake up and again be checked to see if it's ready to be passed to the thread pool.
    def reactor_wakeup(client)
      shutdown = !@queue_requests
      if client.try_to_finish || (shutdown && !client.can_close?)
        @thread_pool << client
      elsif shutdown || client.timeout == 0
        client.timeout!
      else
        client.set_timeout(@first_data_timeout)
        false
      end
    rescue StandardError => e
      client_error(e, client)
      client.close
      true
    end

    def handle_servers
      begin
        check = @check
        sockets = [check] + @binder.ios
        pool = @thread_pool
        queue_requests = @queue_requests
        drain = @options[:drain_on_shutdown] ? 0 : nil

        addr_send_name, addr_value = case @options[:remote_address]
        when :value
          [:peerip=, @options[:remote_address_value]]
        when :header
          [:remote_addr_header=, @options[:remote_address_header]]
        when :proxy_protocol
          [:expect_proxy_proto=, @options[:remote_address_proxy_protocol]]
        else
          [nil, nil]
        end

        while @status == :run || (drain && shutting_down?)
          begin
            ios = IO.select sockets, nil, nil, (shutting_down? ? 0 : nil)
            break unless ios
            ios.first.each do |sock|
              if sock == check
                break if handle_check
              else
                pool.wait_until_not_full
                pool.wait_for_less_busy_worker(@options[:wait_for_less_busy_worker])

                io = begin
                  sock.accept_nonblock
                rescue IO::WaitReadable
                  next
                end
                drain += 1 if shutting_down?
                pool << Client.new(io, @binder.env(sock)).tap { |c|
                  c.listener = sock
                  c.send(addr_send_name, addr_value) if addr_value
                }
              end
            end
          rescue IOError, Errno::EBADF
            # In the case that any of the sockets are unexpectedly close.
            raise
          rescue StandardError => e
            @events.unknown_error e, nil, "Listen loop"
          end
        end

        @events.debug "Drained #{drain} additional connections." if drain
        @events.fire :state, @status

        if queue_requests
          @queue_requests = false
          @reactor.shutdown
        end
        graceful_shutdown if @status == :stop || @status == :restart
      rescue Exception => e
        @events.unknown_error e, nil, "Exception handling servers"
      ensure
        # RuntimeError is Ruby 2.2 issue, can't modify frozen IOError
        # Errno::EBADF is infrequently raised
        [@check, @notify].each do |io|
          begin
            io.close unless io.closed?
          rescue Errno::EBADF, RuntimeError
          end
        end
        @notify = nil
        @check = nil
      end

      @events.fire :state, :done
    end

    # :nodoc:
    def handle_check
      cmd = @check.read(1)

      case cmd
      when STOP_COMMAND
        @status = :stop
        return true
      when HALT_COMMAND
        @status = :halt
        return true
      when RESTART_COMMAND
        @status = :restart
        return true
      end

      false
    end

    # Given a connection on +client+, handle the incoming requests,
    # or queue the connection in the Reactor if no request is available.
    #
    # This method is called from a ThreadPool worker thread.
    #
    # This method supports HTTP Keep-Alive so it may, depending on if the client
    # indicates that it supports keep alive, wait for another request before
    # returning.
    #
    # Return true if one or more requests were processed.
    def process_client(client, buffer)
      # Advertise this server into the thread
      Thread.current[ThreadLocalKey] = self

      clean_thread_locals = @options[:clean_thread_locals]
      close_socket = true

      requests = 0

      begin
        if @queue_requests &&
          !client.eagerly_finish

          client.set_timeout(@first_data_timeout)
          if @reactor.add client
            close_socket = false
            return false
          end
        end

        with_force_shutdown(client) do
          client.finish(@first_data_timeout)
        end

        while true
          @requests_count += 1
          case handle_request(client, buffer, requests + 1)
          when false
            break
          when :async
            close_socket = false
            break
          when true
            buffer.reset

            ThreadPool.clean_thread_locals if clean_thread_locals

            requests += 1

            # As an optimization, try to read the next request from the
            # socket for a short time before returning to the reactor.
            fast_check = @status == :run

            # Always pass the client back to the reactor after a reasonable
            # number of inline requests if there are other requests pending.
            fast_check = false if requests >= @max_fast_inline &&
              @thread_pool.backlog > 0

            next_request_ready = with_force_shutdown(client) do
              client.reset(fast_check)
            end

            unless next_request_ready
              break unless @queue_requests
              client.set_timeout @persistent_timeout
              if @reactor.add client
                close_socket = false
                break
              end
            end
          end
        end
        true
      rescue StandardError => e
        client_error(e, client)
        # The ensure tries to close +client+ down
        requests > 0
      ensure
        buffer.reset

        begin
          client.close if close_socket
        rescue IOError, SystemCallError
          Puma::Util.purge_interrupt_queue
          # Already closed
        rescue StandardError => e
          @events.unknown_error e, nil, "Client"
        end
      end
    end

    # Triggers a client timeout if the thread-pool shuts down
    # during execution of the provided block.
    def with_force_shutdown(client, &block)
      @thread_pool.with_force_shutdown(&block)
    rescue ThreadPool::ForceShutdown
      client.timeout!
    end

    # :nocov:

    # Handle various error types thrown by Client I/O operations.
    def client_error(e, client)
      # Swallow, do not log
      return if [ConnectionError, EOFError].include?(e.class)

      lowlevel_error(e, client.env)
      case e
      when MiniSSL::SSLError
        @events.ssl_error e, client.io
      when HttpParserError
        client.write_error(400)
        @events.parse_error e, client
      when HttpParserError501
        client.write_error(501)
        @events.parse_error e, client
      else
        client.write_error(500)
        @events.unknown_error e, nil, "Read"
      end
    end

    # A fallback rack response if +@app+ raises as exception.
    #
    def lowlevel_error(e, env, status=500)
      if handler = @options[:lowlevel_error_handler]
        if handler.arity == 1
          return handler.call(e)
        elsif handler.arity == 2
          return handler.call(e, env)
        else
          return handler.call(e, env, status)
        end
      end

      if @leak_stack_on_error
        backtrace = e.backtrace.nil? ? '<no backtrace available>' : e.backtrace.join("\n")
        [status, {}, ["Puma caught this error: #{e.message} (#{e.class})\n#{backtrace}"]]
      else
        [status, {}, ["An unhandled lowlevel error occurred. The application logs may have details.\n"]]
      end
    end

    # Wait for all outstanding requests to finish.
    #
    def graceful_shutdown
      if @options[:shutdown_debug]
        threads = Thread.list
        total = threads.size

        pid = Process.pid

        $stdout.syswrite "#{pid}: === Begin thread backtrace dump ===\n"

        threads.each_with_index do |t,i|
          $stdout.syswrite "#{pid}: Thread #{i+1}/#{total}: #{t.inspect}\n"
          $stdout.syswrite "#{pid}: #{t.backtrace.join("\n#{pid}: ")}\n\n"
        end
        $stdout.syswrite "#{pid}: === End thread backtrace dump ===\n"
      end

      if @status != :restart
        @binder.close
      end

      if @thread_pool
        if timeout = @options[:force_shutdown_after]
          @thread_pool.shutdown timeout.to_f
        else
          @thread_pool.shutdown
        end
      end
    end

    def notify_safely(message)
      @notify << message
    rescue IOError, NoMethodError, Errno::EPIPE
      # The server, in another thread, is shutting down
      Puma::Util.purge_interrupt_queue
    rescue RuntimeError => e
      # Temporary workaround for https://bugs.ruby-lang.org/issues/13239
      if e.message.include?('IOError')
        Puma::Util.purge_interrupt_queue
      else
        raise e
      end
    end
    private :notify_safely

    # Stops the acceptor thread and then causes the worker threads to finish
    # off the request queue before finally exiting.

    def stop(sync=false)
      notify_safely(STOP_COMMAND)
      @thread.join if @thread && sync
    end

    def halt(sync=false)
      notify_safely(HALT_COMMAND)
      @thread.join if @thread && sync
    end

    def begin_restart(sync=false)
      notify_safely(RESTART_COMMAND)
      @thread.join if @thread && sync
    end

    def shutting_down?
      @status == :stop || @status == :restart
    end

    # List of methods invoked by #stats.
    # @version 5.0.0
    STAT_METHODS = [:backlog, :running, :pool_capacity, :max_threads, :requests_count].freeze

    # Returns a hash of stats about the running server for reporting purposes.
    # @version 5.0.0
    # @!attribute [r] stats
    def stats
      STAT_METHODS.map {|name| [name, send(name) || 0]}.to_h
    end
  end
end
