# frozen_string_literal: true

module Net
  class IMAP
    module SASL

      # SASL::ProtocolAdapters modules are meant to be used as mixins for
      # SASL::ClientAdapter and its subclasses.  Where the client adapter must
      # be customized for each client library, the protocol adapter mixin
      # handles \SASL requirements that are part of the protocol specification,
      # but not specific to any particular client library.  In particular, see
      # {RFC4422 §4}[https://www.rfc-editor.org/rfc/rfc4422.html#section-4]
      #
      # === Interface
      #
      # >>>
      #   NOTE: This API is experimental, and may change.
      #
      # - {#command_name}[rdoc-ref:Generic#command_name] -- The name of the
      #   command used to to initiate an authentication exchange.
      # - {#service}[rdoc-ref:Generic#service] -- The GSSAPI service name.
      # - {#encode_ir}[rdoc-ref:Generic#encode_ir]--Encodes an initial response.
      # - {#decode}[rdoc-ref:Generic#decode] -- Decodes a server challenge.
      # - {#encode}[rdoc-ref:Generic#encode] -- Encodes a client response.
      # - {#cancel_response}[rdoc-ref:Generic#cancel_response] -- The encoded
      #   client response used to cancel an authentication exchange.
      #
      # Other protocol requirements of the \SASL authentication exchange are
      # handled by SASL::ClientAdapter.
      #
      # === Included protocol adapters
      #
      # - Generic -- a basic implementation of all of the methods listed above.
      # - IMAP -- An adapter for the IMAP4 protocol.
      # - SMTP -- An adapter for the \SMTP protocol with the +AUTH+ capability.
      # - POP  -- An adapter for the POP3  protocol with the +SASL+ capability.
      module ProtocolAdapters
        # See SASL::ProtocolAdapters@Interface.
        module Generic
          # The name of the protocol command used to initiate a \SASL
          # authentication exchange.
          #
          # The generic implementation returns <tt>"AUTHENTICATE"</tt>.
          def command_name;     "AUTHENTICATE" end

          # A service name from the {GSSAPI/Kerberos/SASL Service Names
          # registry}[https://www.iana.org/assignments/gssapi-service-names/gssapi-service-names.xhtml].
          #
          # The generic implementation returns <tt>"host"</tt>, which is the
          # generic GSSAPI host-based service name.
          def service;          "host" end

          # Encodes an initial response string.
          #
          # The generic implementation returns the result of #encode, or returns
          # <tt>"="</tt> when +string+ is empty.
          def encode_ir(string) string.empty? ? "=" : encode(string) end

          # Encodes a client response string.
          #
          # The generic implementation returns the Base64 encoding of +string+.
          def encode(string)    [string].pack("m0") end

          # Decodes a server challenge string.
          #
          # The generic implementation returns the Base64 decoding of +string+.
          def decode(string)    string.unpack1("m0") end

          # Returns the message used by the client to abort an authentication
          # exchange.
          #
          # The generic implementation returns <tt>"*"</tt>.
          def cancel_response;  "*" end
        end

        # See RFC-3501 (IMAP4rev1), RFC-4959 (SASL-IR capability),
        # and RFC-9051 (IMAP4rev2).
        module IMAP
          include Generic
          def service; "imap" end
        end

        # See RFC-4954 (AUTH capability).
        module SMTP
          include Generic
          def command_name; "AUTH" end
          def service; "smtp" end
        end

        # See RFC-5034 (SASL capability).
        module POP
          include Generic
          def command_name; "AUTH" end
          def service; "pop" end
        end

      end

    end
  end
end
