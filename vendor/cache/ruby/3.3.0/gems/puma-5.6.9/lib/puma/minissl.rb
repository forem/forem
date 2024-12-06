# frozen_string_literal: true

begin
  require 'io/wait'
rescue LoadError
end

# need for Puma::MiniSSL::OPENSSL constants used in `HAS_TLS1_3`
require 'puma/puma_http11'

module Puma
  module MiniSSL
    # Define constant at runtime, as it's easy to determine at built time,
    # but Puma could (it shouldn't) be loaded with an older OpenSSL version
    # @version 5.0.0
    HAS_TLS1_3 = !IS_JRUBY &&
      (OPENSSL_VERSION[/ \d+\.\d+\.\d+/].split('.').map(&:to_i) <=> [1,1,1]) != -1 &&
      (OPENSSL_LIBRARY_VERSION[/ \d+\.\d+\.\d+/].split('.').map(&:to_i) <=> [1,1,1]) !=-1

    class Socket
      def initialize(socket, engine)
        @socket = socket
        @engine = engine
        @peercert = nil
      end

      # @!attribute [r] to_io
      def to_io
        @socket
      end

      def closed?
        @socket.closed?
      end

      # Returns a two element array,
      # first is protocol version (SSL_get_version),
      # second is 'handshake' state (SSL_state_string)
      #
      # Used for dropping tcp connections to ssl.
      # See OpenSSL ssl/ssl_stat.c SSL_state_string for info
      # @!attribute [r] ssl_version_state
      # @version 5.0.0
      #
      def ssl_version_state
        IS_JRUBY ? [nil, nil] : @engine.ssl_vers_st
      end

      # Used to check the handshake status, in particular when a TCP connection
      # is made with TLSv1.3 as an available protocol
      # @version 5.0.0
      def bad_tlsv1_3?
        HAS_TLS1_3 && @engine.ssl_vers_st == ['TLSv1.3', 'SSLERR']
      end
      private :bad_tlsv1_3?

      def readpartial(size)
        while true
          output = @engine.read
          return output if output

          data = @socket.readpartial(size)
          @engine.inject(data)
          output = @engine.read

          return output if output

          while neg_data = @engine.extract
            @socket.write neg_data
          end
        end
      end

      def engine_read_all
        output = @engine.read
        while output and additional_output = @engine.read
          output << additional_output
        end
        output
      end

      def read_nonblock(size, *_)
        # *_ is to deal with keyword args that were added
        # at some point (and being used in the wild)
        while true
          output = engine_read_all
          return output if output

          data = @socket.read_nonblock(size, exception: false)
          if data == :wait_readable || data == :wait_writable
            # It would make more sense to let @socket.read_nonblock raise
            # EAGAIN if necessary but it seems like it'll misbehave on Windows.
            # I don't have a Windows machine to debug this so I can't explain
            # exactly whats happening in that OS. Please let me know if you
            # find out!
            #
            # In the meantime, we can emulate the correct behavior by
            # capturing :wait_readable & :wait_writable and raising EAGAIN
            # ourselves.
            raise IO::EAGAINWaitReadable
          elsif data.nil?
            raise SSLError.exception "HTTP connection?" if bad_tlsv1_3?
            return nil
          end

          @engine.inject(data)
          output = engine_read_all

          return output if output

          while neg_data = @engine.extract
            @socket.write neg_data
          end
        end
      end

      def write(data)
        return 0 if data.empty?

        data_size = data.bytesize
        need = data_size

        while true
          wrote = @engine.write data

          enc_wr = ''.dup
          while (enc = @engine.extract)
            enc_wr << enc
          end
          @socket.write enc_wr unless enc_wr.empty?

          need -= wrote

          return data_size if need == 0

          data = data.byteslice(wrote..-1)
        end
      end

      alias_method :syswrite, :write
      alias_method :<<, :write

      # This is a temporary fix to deal with websockets code using
      # write_nonblock.

      # The problem with implementing it properly
      # is that it means we'd have to have the ability to rewind
      # an engine because after we write+extract, the socket
      # write_nonblock call might raise an exception and later
      # code would pass the same data in, but the engine would think
      # it had already written the data in.
      #
      # So for the time being (and since write blocking is quite rare),
      # go ahead and actually block in write_nonblock.
      #
      def write_nonblock(data, *_)
        write data
      end

      def flush
        @socket.flush
      end

      def close
        begin
          unless @engine.shutdown
            while alert_data = @engine.extract
              @socket.write alert_data
            end
          end
        rescue IOError, SystemCallError
          Puma::Util.purge_interrupt_queue
          # nothing
        ensure
          @socket.close
        end
      end

      # @!attribute [r] peeraddr
      def peeraddr
        @socket.peeraddr
      end

      # @!attribute [r] peercert
      def peercert
        return @peercert if @peercert

        raw = @engine.peercert
        return nil unless raw

        @peercert = OpenSSL::X509::Certificate.new raw
      end
    end

    if IS_JRUBY
      OPENSSL_NO_SSL3 = false
      OPENSSL_NO_TLS1 = false

      class SSLError < StandardError
        # Define this for jruby even though it isn't used.
      end
    end

    class Context
      attr_accessor :verify_mode
      attr_reader :no_tlsv1, :no_tlsv1_1

      def initialize
        @no_tlsv1   = false
        @no_tlsv1_1 = false
        @key = nil
        @cert = nil
        @key_pem = nil
        @cert_pem = nil
      end

      def check_file(file, desc)
        raise ArgumentError, "#{desc} file '#{file}' does not exist" unless File.exist? file
        raise ArgumentError, "#{desc} file '#{file}' is not readable" unless File.readable? file
      end

      if IS_JRUBY
        # jruby-specific Context properties: java uses a keystore and password pair rather than a cert/key pair
        attr_reader :keystore
        attr_accessor :keystore_pass
        attr_accessor :ssl_cipher_list

        def keystore=(keystore)
          check_file keystore, 'Keystore'
          @keystore = keystore
        end

        def check
          raise "Keystore not configured" unless @keystore
        end

      else
        # non-jruby Context properties
        attr_reader :key
        attr_reader :cert
        attr_reader :ca
        attr_reader :cert_pem
        attr_reader :key_pem
        attr_accessor :ssl_cipher_filter
        attr_accessor :verification_flags

        def key=(key)
          check_file key, 'Key'
          @key = key
        end

        def cert=(cert)
          check_file cert, 'Cert'
          @cert = cert
        end

        def ca=(ca)
          check_file ca, 'ca'
          @ca = ca
        end

        def cert_pem=(cert_pem)
          raise ArgumentError, "'cert_pem' is not a String" unless cert_pem.is_a? String
          @cert_pem = cert_pem
        end

        def key_pem=(key_pem)
          raise ArgumentError, "'key_pem' is not a String" unless key_pem.is_a? String
          @key_pem = key_pem
        end

        def check
          raise "Key not configured" if @key.nil? && @key_pem.nil?
          raise "Cert not configured" if @cert.nil? && @cert_pem.nil?
        end
      end

      # disables TLSv1
      # @!attribute [w] no_tlsv1=
      def no_tlsv1=(tlsv1)
        raise ArgumentError, "Invalid value of no_tlsv1=" unless ['true', 'false', true, false].include?(tlsv1)
        @no_tlsv1 = tlsv1
      end

      # disables TLSv1 and TLSv1.1.  Overrides `#no_tlsv1=`
      # @!attribute [w] no_tlsv1_1=
      def no_tlsv1_1=(tlsv1_1)
        raise ArgumentError, "Invalid value of no_tlsv1_1=" unless ['true', 'false', true, false].include?(tlsv1_1)
        @no_tlsv1_1 = tlsv1_1
      end

    end

    VERIFY_NONE = 0
    VERIFY_PEER = 1
    VERIFY_FAIL_IF_NO_PEER_CERT = 2

    # https://github.com/openssl/openssl/blob/master/include/openssl/x509_vfy.h.in
    # /* Certificate verify flags */
    VERIFICATION_FLAGS = {
      "USE_CHECK_TIME"       => 0x2,
      "CRL_CHECK"            => 0x4,
      "CRL_CHECK_ALL"        => 0x8,
      "IGNORE_CRITICAL"      => 0x10,
      "X509_STRICT"          => 0x20,
      "ALLOW_PROXY_CERTS"    => 0x40,
      "POLICY_CHECK"         => 0x80,
      "EXPLICIT_POLICY"      => 0x100,
      "INHIBIT_ANY"          => 0x200,
      "INHIBIT_MAP"          => 0x400,
      "NOTIFY_POLICY"        => 0x800,
      "EXTENDED_CRL_SUPPORT" => 0x1000,
      "USE_DELTAS"           => 0x2000,
      "CHECK_SS_SIGNATURE"   => 0x4000,
      "TRUSTED_FIRST"        => 0x8000,
      "SUITEB_128_LOS_ONLY"  => 0x10000,
      "SUITEB_192_LOS"       => 0x20000,
      "SUITEB_128_LOS"       => 0x30000,
      "PARTIAL_CHAIN"        => 0x80000,
      "NO_ALT_CHAINS"        => 0x100000,
      "NO_CHECK_TIME"        => 0x200000
    }.freeze

    class Server
      def initialize(socket, ctx)
        @socket = socket
        @ctx = ctx
        @eng_ctx = IS_JRUBY ? @ctx : SSLContext.new(ctx)
      end

      def accept
        @ctx.check
        io = @socket.accept
        engine = Engine.server @eng_ctx
        Socket.new io, engine
      end

      def accept_nonblock
        @ctx.check
        io = @socket.accept_nonblock
        engine = Engine.server @eng_ctx
        Socket.new io, engine
      end

      # @!attribute [r] to_io
      def to_io
        @socket
      end

      # @!attribute [r] addr
      # @version 5.0.0
      def addr
        @socket.addr
      end

      def close
        @socket.close unless @socket.closed?       # closed? call is for Windows
      end

      def closed?
        @socket.closed?
      end
    end
  end
end
