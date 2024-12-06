# frozen_string_literal: true

module Net
  class IMAP
    module SASL

      # AuthenticationExchange is used internally by Net::IMAP#authenticate.
      # But the API is still *experimental*, and may change.
      #
      # TODO: catch exceptions in #process and send #cancel_response.
      # TODO: raise an error if the command succeeds after being canceled.
      # TODO: use with more clients, to verify the API can accommodate them.
      # TODO: pass ClientAdapter#service to SASL.authenticator
      #
      # An AuthenticationExchange represents a single attempt to authenticate
      # a SASL client to a SASL server.  It is created from a client adapter, a
      # mechanism name, and a mechanism authenticator.  When #authenticate is
      # called, it will send the appropriate authenticate command to the server,
      # returning the client response on success and raising an exception on
      # failure.
      #
      # In most cases, the client will not need to use
      # SASL::AuthenticationExchange directly at all.  Instead, use
      # SASL::ClientAdapter#authenticate.  If customizations are needed, the
      # custom client adapter is probably the best place for that code.
      #
      #     def authenticate(...)
      #       MyClient::SASLAdapter.new(self).authenticate(...)
      #     end
      #
      # SASL::ClientAdapter#authenticate delegates to ::authenticate, like so:
      #
      #     def authenticate(...)
      #       sasl_adapter = MyClient::SASLAdapter.new(self)
      #       SASL::AuthenticationExchange.authenticate(sasl_adapter, ...)
      #     end
      #
      # ::authenticate simply delegates to ::build and #authenticate, like so:
      #
      #     def authenticate(...)
      #       sasl_adapter = MyClient::SASLAdapter.new(self)
      #       SASL::AuthenticationExchange
      #         .build(sasl_adapter, ...)
      #         .authenticate
      #     end
      #
      # And ::build delegates to SASL.authenticator and ::new, like so:
      #
      #     def authenticate(mechanism, ...)
      #       sasl_adapter = MyClient::SASLAdapter.new(self)
      #       authenticator = SASL.authenticator(mechanism, ...)
      #       SASL::AuthenticationExchange
      #         .new(sasl_adapter, mechanism, authenticator)
      #         .authenticate
      #     end
      #
      class AuthenticationExchange
        # Convenience method for <tt>build(...).authenticate</tt>
        #
        # See also: SASL::ClientAdapter#authenticate
        def self.authenticate(...) build(...).authenticate end

        # Convenience method to combine the creation of a new authenticator and
        # a new Authentication exchange.
        #
        # +client+ must be an instance of SASL::ClientAdapter.
        #
        # +mechanism+ must be a SASL mechanism name, as a string or symbol.
        #
        # +sasl_ir+ allows or disallows sending an "initial response", depending
        # also on whether the server capabilities, mechanism authenticator, and
        # client adapter all support it.  Defaults to +true+.
        #
        # +mechanism+, +args+, +kwargs+, and +block+ are all forwarded to
        # SASL.authenticator.  Use the +registry+ kwarg to override the global
        # SASL::Authenticators registry.
        def self.build(client, mechanism, *args, sasl_ir: true, **kwargs, &block)
          authenticator = SASL.authenticator(mechanism, *args, **kwargs, &block)
          new(client, mechanism, authenticator, sasl_ir: sasl_ir)
        end

        attr_reader :mechanism, :authenticator

        def initialize(client, mechanism, authenticator, sasl_ir: true)
          @client = client
          @mechanism = Authenticators.normalize_name(mechanism)
          @authenticator = authenticator
          @sasl_ir = sasl_ir
          @processed = false
        end

        # Call #authenticate to execute an authentication exchange for #client
        # using #authenticator.  Authentication failures will raise an
        # exception.  Any exceptions other than those in RESPONSE_ERRORS will
        # drop the connection.
        def authenticate
          client.run_command(mechanism, initial_response) { process _1 }
            .tap { raise AuthenticationIncomplete, _1 unless done? }
        rescue *client.response_errors
          raise # but don't drop the connection
        rescue
          client.drop_connection
          raise
        rescue Exception # rubocop:disable Lint/RescueException
          client.drop_connection!
          raise
        end

        def send_initial_response?
          @sasl_ir &&
            authenticator.respond_to?(:initial_response?) &&
            authenticator.initial_response? &&
            client.sasl_ir_capable? &&
            client.auth_capable?(mechanism)
        end

        def done?
          authenticator.respond_to?(:done?) ? authenticator.done? : @processed
        end

        private

        attr_reader :client

        def initial_response
          return unless send_initial_response?
          client.encode_ir authenticator.process nil
        end

        def process(challenge)
          client.encode authenticator.process client.decode challenge
        ensure
          @processed = true
        end

      end
    end
  end
end
