require "delegate"

module Fog
  module SSH
    def self.new(address, username, options = {})
      if Fog.mocking?
        Fog::SSH::Mock.new(address, username, options)
      else
        Fog::SSH::Real.new(address, username, options)
      end
    end

    class Mock
      def self.data
        @data ||= Hash.new do |hash, key|
          hash[key] = []
        end
      end

      def self.reset
        @data = nil
      end

      def initialize(address, username, options)
        @address  = address
        @username = username
        @options  = options
      end

      def run(commands, &_blk)
        self.class.data[@address] << { :commands => commands, :username => @username, :options => @options }
      end
    end

    class Real
      def initialize(address, username, options)
        assert_net_ssh_loaded
        @address  = address
        @username = username
        @options = build_options(options)
      end

      def run(commands, &blk)
        commands = [*commands]
        results  = []
        begin
          Net::SSH.start(@address, @username, @options) do |ssh|
            commands.each do |command|
              result = Result.new(command)
              ssh.open_channel do |ssh_channel|
                ssh_channel.request_pty
                ssh_channel.exec(command) do |channel, success|
                  unless success
                    raise "Could not execute command: #{command.inspect}"
                  end

                  channel.on_data do |_ch, data|
                    result.stdout << data
                    yield [data, ""] if blk
                  end

                  channel.on_extended_data do |_ch, type, data|
                    next unless type == 1
                    result.stderr << data
                    yield ["", data] if blk
                  end

                  channel.on_request("exit-status") do |_ch, data|
                    result.status = data.read_long
                  end

                  channel.on_request("exit-signal") do |_ch, _data|
                    result.status = 255
                  end
                end
              end
              ssh.loop
              results << result
            end
          end
        rescue Net::SSH::HostKeyMismatch => exception
          exception.remember_host!
          sleep 0.2
          retry
        end
        results
      end

      private

      def assert_net_ssh_loaded
        begin
          require "net/ssh"
        rescue LoadError
          Fog::Logger.warning("'net/ssh' missing, please install and try again.")
          exit(1)
        end
      end

      # Modifies the given `options` hash AND returns a new hash.
      # TODO: Probably shouldn't modify the given hash.
      def build_options(options)
        validate_options(options)
        merge_default_options_into(options)
      end

      def merge_default_options_into(options)
        options[:timeout] ||= 30
        if options[:key_data] || options[:keys]
          options[:keys_only] = true
          # Explicitly set these so net-ssh doesn"t add the default keys
          # as seen at https://github.com/net-ssh/net-ssh/blob/master/lib/net/ssh/authentication/session.rb#L131-146
          options[:keys] = [] unless options[:keys]
          options[:key_data] = [] unless options[:key_data]
        end

        # net-ssh has deprecated :paranoid in favor of :verify_host_key
        # https://github.com/net-ssh/net-ssh/pull/524
        opts = { :paranoid => false, :verify_host_key => :never }.merge(options)
        if Net::SSH::VALID_OPTIONS.include? :verify_host_key
          opts.delete(:paranoid)
        end
        opts[:verify_host_key] = false unless Net::SSH::Verifiers.const_defined?(:Never)
        opts
      end

      def validate_options(options)
        key_manager = Net::SSH::Authentication::KeyManager.new(nil, options)
        unless options[:key_data] || options[:keys] || options[:password] || key_manager.agent
          raise ArgumentError, ":key_data, :keys, :password or a loaded ssh-agent is required to initialize SSH"
        end
      end
    end

    class Result
      attr_accessor :command, :stderr, :stdout, :status

      def display_stdout
        data = stdout.split("\r\n")
        if data.is_a?(String)
          Fog::Formatador.display_line(data)
        elsif data.is_a?(Array)
          Fog::Formatador.display_lines(data)
        end
      end

      def display_stderr
        Fog::Formatador.display_line(stderr.split("\r\n"))
      end

      def initialize(command)
        @command = command
        @stderr = ""
        @stdout = ""
      end
    end
  end
end
