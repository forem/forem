# frozen_string_literal: true

require "forwardable"

module Net
  class IMAP
    module SASL

      # This API is *experimental*, and may change.
      #
      # TODO: use with more clients, to verify the API can accommodate them.
      #
      # Represents the client to a SASL::AuthenticationExchange.  By default,
      # most methods simply delegate to #client.  Clients should subclass
      # SASL::ClientAdapter and override methods as needed to match the
      # semantics of this API to their API.
      #
      # Subclasses should also include a protocol adapter mixin when the default
      # ProtocolAdapters::Generic isn't sufficient.
      #
      # === Protocol Requirements
      #
      # {RFC4422 §4}[https://www.rfc-editor.org/rfc/rfc4422.html#section-4]
      # lists requirements for protocol specifications to offer SASL.  Where
      # possible, ClientAdapter delegates the handling of these requirements to
      # SASL::ProtocolAdapters.
      class ClientAdapter
        extend Forwardable

        include ProtocolAdapters::Generic

        # The client that handles communication with the protocol server.
        #
        # Most ClientAdapter methods are simply delegated to #client by default.
        attr_reader :client

        # +command_proc+ can used to avoid exposing private methods on #client.
        # It's value is set by the block that is passed to ::new, and it is used
        # by the default implementation of #run_command.  Subclasses that
        # override #run_command may use #command_proc for any other purpose they
        # find useful.
        #
        # In the default implementation of #run_command, command_proc is called
        # with the protocols authenticate +command+ name, the +mechanism+ name,
        # an _optional_ +initial_response+ argument, and a +continuations+
        # block.  command_proc must run the protocol command with the arguments
        # sent to it, _yield_ the payload of each continuation, respond to the
        # continuation with the result of each _yield_, and _return_ the
        # command's successful result.  Non-successful results *MUST* raise
        # an exception.
        attr_reader :command_proc

        # By default, this simply sets the #client and #command_proc attributes.
        # Subclasses may override it, for example: to set the appropriate
        # command_proc automatically.
        def initialize(client, &command_proc)
          @client, @command_proc = client, command_proc
        end

        # Attempt to authenticate #client to the server.
        #
        # By default, this simply delegates to
        # AuthenticationExchange.authenticate.
        def authenticate(...) AuthenticationExchange.authenticate(self, ...) end

        ##
        # method: sasl_ir_capable?
        # Do the protocol, server, and client all support an initial response?
        def_delegator :client, :sasl_ir_capable?

        ##
        # method: auth_capable?
        # call-seq: auth_capable?(mechanism)
        #
        # Does the server advertise support for the +mechanism+?
        def_delegator :client, :auth_capable?

        # Calls command_proc with +command_name+ (see
        # SASL::ProtocolAdapters::Generic#command_name),
        # +mechanism+, +initial_response+, and a +continuations_handler+ block.
        # The +initial_response+ is optional; when it's nil, it won't be sent to
        # command_proc.
        #
        # Yields each continuation payload, responds to the server with the
        # result of each yield, and returns the result.  Non-successful results
        # *MUST* raise an exception.  Exceptions in the block *MUST* cause the
        # command to fail.
        #
        # Subclasses that override this may use #command_proc differently.
        def run_command(mechanism, initial_response = nil, &continuations_handler)
          command_proc or raise Error, "initialize with block or override"
          args = [command_name, mechanism, initial_response].compact
          command_proc.call(*args, &continuations_handler)
        end

        ##
        # method: host
        # The hostname to which the client connected.
        def_delegator :client, :host

        ##
        # method: port
        # The destination port to which the client connected.
        def_delegator :client, :port

        # Returns an array of server responses errors raised by run_command.
        # Exceptions in this array won't drop the connection.
        def response_errors; [] end

        ##
        # method: drop_connection
        # Drop the connection gracefully, sending a "LOGOUT" command as needed.
        def_delegator :client, :drop_connection

        ##
        # method: drop_connection!
        # Drop the connection abruptly, closing the socket without logging out.
        def_delegator :client, :drop_connection!

      end
    end
  end
end
