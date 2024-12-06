module Puma
  module MiniSSL
    class ContextBuilder
      def initialize(params, events)
        @params = params
        @events = events
      end

      def context
        ctx = MiniSSL::Context.new

        if defined?(JRUBY_VERSION)
          unless params['keystore']
            events.error "Please specify the Java keystore via 'keystore='"
          end

          ctx.keystore = params['keystore']

          unless params['keystore-pass']
            events.error "Please specify the Java keystore password  via 'keystore-pass='"
          end

          ctx.keystore_pass = params['keystore-pass']
          ctx.ssl_cipher_list = params['ssl_cipher_list'] if params['ssl_cipher_list']
        else
          if params['key'].nil? && params['key_pem'].nil?
            events.error "Please specify the SSL key via 'key=' or 'key_pem='"
          end

          ctx.key = params['key'] if params['key']
          ctx.key_pem = params['key_pem'] if params['key_pem']

          if params['cert'].nil? && params['cert_pem'].nil?
            events.error "Please specify the SSL cert via 'cert=' or 'cert_pem='"
          end

          ctx.cert = params['cert'] if params['cert']
          ctx.cert_pem = params['cert_pem'] if params['cert_pem']

          if ['peer', 'force_peer'].include?(params['verify_mode'])
            unless params['ca']
              events.error "Please specify the SSL ca via 'ca='"
            end
          end

          ctx.ca = params['ca'] if params['ca']
          ctx.ssl_cipher_filter = params['ssl_cipher_filter'] if params['ssl_cipher_filter']
        end

        ctx.no_tlsv1 = true if params['no_tlsv1'] == 'true'
        ctx.no_tlsv1_1 = true if params['no_tlsv1_1'] == 'true'

        if params['verify_mode']
          ctx.verify_mode = case params['verify_mode']
                            when "peer"
                              MiniSSL::VERIFY_PEER
                            when "force_peer"
                              MiniSSL::VERIFY_PEER | MiniSSL::VERIFY_FAIL_IF_NO_PEER_CERT
                            when "none"
                              MiniSSL::VERIFY_NONE
                            else
                              events.error "Please specify a valid verify_mode="
                              MiniSSL::VERIFY_NONE
                            end
        end

        if params['verification_flags']
          ctx.verification_flags = params['verification_flags'].split(',').
            map { |flag| MiniSSL::VERIFICATION_FLAGS.fetch(flag) }.
            inject { |sum, flag| sum ? sum | flag : flag }
        end

        ctx
      end

      private

      attr_reader :params, :events
    end
  end
end
