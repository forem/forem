# frozen_string_literal: true

module Stripe
  module APIOperations
    module Request
      module ClassMethods
        def execute_resource_request(method, url,
                                     params = {}, opts = {})
          execute_resource_request_internal(
            :execute_request, method, url, params, opts
          )
        end

        def execute_resource_request_stream(method, url,
                                            params = {}, opts = {},
                                            &read_body_chunk_block)
          execute_resource_request_internal(
            :execute_request_stream,
            method,
            url,
            params,
            opts,
            &read_body_chunk_block
          )
        end

        private def execute_resource_request_internal(client_request_method_sym,
                                                      method, url,
                                                      params, opts,
                                                      &read_body_chunk_block)
          params ||= {}

          error_on_invalid_params(params)
          warn_on_opts_in_params(params)

          opts = Util.normalize_opts(opts)
          error_on_non_string_user_opts(opts)

          opts[:client] ||= StripeClient.active_client

          headers = opts.clone
          api_key = headers.delete(:api_key)
          api_base = headers.delete(:api_base)
          client = headers.delete(:client)
          # Assume all remaining opts must be headers

          resp, opts[:api_key] = client.send(
            client_request_method_sym,
            method, url,
            api_base: api_base, api_key: api_key,
            headers: headers, params: params,
            &read_body_chunk_block
          )

          # Hash#select returns an array before 1.9
          opts_to_persist = {}
          opts.each do |k, v|
            opts_to_persist[k] = v if Util::OPTS_PERSISTABLE.include?(k)
          end

          [resp, opts_to_persist]
        end

        # This method used to be called `request`, but it's such a short name
        # that it eventually conflicted with the name of a field on an API
        # resource (specifically, `Event#request`), so it was renamed to
        # something more unique.
        #
        # The former name had been around for just about forever though, and
        # although all internal uses have been renamed, I've left this alias in
        # place for backwards compatibility. Consider removing it on the next
        # major.
        alias request execute_resource_request

        private def error_on_non_string_user_opts(opts)
          Util::OPTS_USER_SPECIFIED.each do |opt|
            next unless opts.key?(opt)

            val = opts[opt]
            next if val.nil?
            next if val.is_a?(String)

            raise ArgumentError,
                  "request option '#{opt}' should be a string value " \
                    "(was a #{val.class})"
          end
        end

        private def error_on_invalid_params(params)
          return if params.nil? || params.is_a?(Hash)

          raise ArgumentError,
                "request params should be either a Hash or nil " \
                  "(was a #{params.class})"
        end

        private def warn_on_opts_in_params(params)
          Util::OPTS_USER_SPECIFIED.each do |opt|
            if params.key?(opt)
              warn("WARNING: '#{opt}' should be in opts instead of params.")
            end
          end
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      protected def execute_resource_request(method, url,
                                             params = {}, opts = {})
        opts = @opts.merge(Util.normalize_opts(opts))
        self.class.execute_resource_request(method, url, params, opts)
      end

      protected def execute_resource_request_stream(method, url,
                                                    params = {}, opts = {},
                                                    &read_body_chunk_block)
        opts = @opts.merge(Util.normalize_opts(opts))
        self.class.execute_resource_request_stream(
          method, url, params, opts, &read_body_chunk_block
        )
      end

      # See notes on `alias` above.
      alias request execute_resource_request
    end
  end
end
