# frozen_string_literal: true

require "aws-sdk-core"

module Honeycomb
  module Aws
    # The version of the aws-sdk-core gem.
    #
    # Aws::VERSION was removed in aws-sdk-core v3.2.1 in favor of
    # Aws::CORE_GEM_VERSION. However, it's still present in aws-sdk v2.
    #
    # @see https://github.com/aws/aws-sdk-ruby/blob/d0c5f6e5a3e83eeda2d1c81f5dd80e5ac562a6dc/gems/aws-sdk-core/CHANGELOG.md#321-2017-09-06
    # @see https://github.com/aws/aws-sdk-ruby/blob/4c40f6e67e763a0f392ba5b1449254426b68a600/aws-sdk-core/lib/aws-sdk-core/version.rb#L2
    SDK_VERSION =
      defined?(::Aws::VERSION) ? ::Aws::VERSION : ::Aws::CORE_GEM_VERSION

    # Instruments AWS clients with Honeycomb events.
    #
    # This plugin is automatically added to any aws-sdk client class your app
    # uses. It uses {SdkHandler} to wrap a Honeycomb span around each
    # invocation of a client object method. Within that span, there is
    # typically at least one actual HTTP API call to Amazon, so each API call
    # is wrapped in a separate span by {ApiHandler}.
    #
    # This plugin adds the following options which you can use to configure
    # your aws-sdk clients:
    #
    # * `:honeycomb` - Boolean indicating whether to enable Honeycomb
    #   instrumentation. Defaults to `true`.
    #
    # * `:honeycomb_client` - Allows you to set a custom Honeycomb client
    #   object. Defaults to the global {Honeycomb.client}.
    #
    # @example Disable the Honeycomb AWS integration globally.
    #   Aws.config.update(honeycomb: false)
    #
    # @example Disable the Honeycomb AWS integration locally.
    #   s3 = Aws::S3::Client.new(honeycomb: false)
    #
    # @example Use a different client globally.
    #   Aws.config.update(honeycomb_client: custom)
    #
    # @example Use a different client locally.
    #   dynamodb = Aws::DynamoDB::Client.new(honeycomb_client: custom)
    #
    # @see https://docs.aws.amazon.com/sdk-for-ruby/v3/api/index.html#Configuration_Options
    # @see SdkHandler
    # @see ApiHandler
    class Plugin < Seahorse::Client::Plugin
      option(
        :honeycomb,
        default: true,
        doc_type: "Boolean",
        docstring: "When `true`, emit Honeycomb events for every SDK/API call.",
      )

      option(
        :honeycomb_client,
        doc_type: Honeycomb::Client,
        docstring: "The Honeycomb client used for sending SDK/API call events.",
      ) { Honeycomb.client }

      def add_handlers(handlers, config)
        return unless config.honeycomb && config.honeycomb_client

        handlers.add(SdkHandler, step: :initialize)
        handlers.add(ApiHandler, step: :sign, priority: 39)
      end
    end

    # An AWS plugin handler that creates spans around SDK calls.
    #
    # Each aws-sdk client provides a one-to-one mapping of methods to logical
    # API operations. {SdkHandler} is responsible for starting the root level
    # AWS span for the SDK method being called.
    #
    # {Plugin} accomplishes this by adding the handler early in the process,
    # around the initialization step. This doesn't necessarily represent the
    # network latency of the API requests being made to Amazon, since SDK calls
    # might involve several underlying operations: request signing, response
    # parsing, retries, redirects, etc. Thus, {ApiHandler} is responsible for
    # creating child spans around individual HTTP API calls. The span created
    # by {SdkHandler} represents the overall result of the method call you made
    # to the aws-sdk client.
    class SdkHandler < Seahorse::Client::Handler
      def call(context)
        setup(context)
        response = @handler.call(context)
        teardown(context, response.error)
        response
      rescue StandardError => e
        teardown(context, e)
        raise e
      ensure
        finish(context)
      end

      private

      def setup(context)
        span = context.config.honeycomb_client.start_span(name: "aws-sdk")
        context[:honeycomb_aws_sdk_span] = span
        context[:honeycomb_aws_sdk_data] = {
          "meta.package" => context[:gem_name] || "aws-sdk",
          "meta.package_version" => context[:gem_version] || SDK_VERSION,
          "aws.region" => context.config.region,
          "aws.service" => context.client.class.identifier,
          "aws.operation" => context.operation_name,
        }

        context.params && context.params.each do |key, value|
          context[:honeycomb_aws_sdk_data]["aws.params.#{key}"] = value
        end

        span.add context[:honeycomb_aws_sdk_data]
      end

      def teardown(context, error)
        span = context[:honeycomb_aws_sdk_span]
        span.add_field "aws.request_id", context[:request_id]
        span.add_field "aws.retries", context.retries
        span.add_field "aws.retry_limit", context.config.retry_limit
        span.add_field "aws.error", error.class.name if error
        span.add_field "aws.error_detail", error.message if error
      end

      def finish(context)
        span = context.metadata.delete(:honeycomb_aws_sdk_span)
        span.send
      end
    end

    # An AWS plugin handler that creates spans around API calls.
    #
    # Each aws-sdk client provides a one-to-one mapping of methods to API
    # operations. However, this doesn't mean that each method results in only
    # one HTTP request to Amazon's servers. There may be request errors,
    # retries, redirects, etc. So whereas {SdkHandler} wraps the logical
    # operation in a span, {ApiHandler} wraps the individual API requests in
    # separate child spans.
    #
    # {Plugin} accomplishes this by adding {ApiHandler} as close to sending as
    # possible, before the client retries requests, follows redirects, or even
    # parses out response errors. That way, a new span is created for every
    # literal HTTP request. But it also means we have to take care to propagate
    # error information to the span correctly, since the stock AWS error
    # handlers are upstream from this one.
    #
    # @see https://github.com/aws/aws-sdk-ruby/blob/767a96db5cb98424a78249dca3f0be802148372e/gems/aws-sdk-s3/lib/aws-sdk-s3/plugins/s3_signer.rb#L36
    # @see https://github.com/aws/aws-sdk-ruby/blob/767a96db5cb98424a78249dca3f0be802148372e/gems/aws-sdk-core/lib/aws-sdk-core/plugins/client_metrics_send_plugin.rb#L9-L11
    # @see https://github.com/aws/aws-sdk-ruby/blob/97b28ccf18558fc908fd56f52741cf3329de9869/gems/aws-sdk-core/lib/seahorse/client/plugins/raise_response_errors.rb
    class ApiHandler < Seahorse::Client::Handler
      def call(context)
        context.config.honeycomb_client.start_span(name: "aws-api") do |span|
          instrument(span, context)
          @handler.call(context)
        end
      end

      private

      def instrument(span, context)
        context[:honeycomb_aws_api_span] = span
        handle_request(context)
        handle_response(context)
      end

      def handle_request(context)
        span = context[:honeycomb_aws_api_span]
        add_aws_api_fields(span, context)
        add_request_fields(span, context)
      end

      def add_aws_api_fields(span, context)
        span.add context[:honeycomb_aws_sdk_data]
        span.add_field "aws.attempt", context.retries + 1
        add_credentials(span, context) if context.config.credentials
        handle_redirect(span, context) if context[:redirect_region]
      end

      def add_credentials(span, context)
        credentials = context.config.credentials.credentials
        span.add_field "aws.access_key_id", credentials.access_key_id
        span.add_field "aws.session_token", credentials.session_token
      end

      def handle_redirect(span, context)
        span.add_field "aws.region", context[:redirect_region]
      end

      def add_request_fields(span, context)
        request = context.http_request
        span.add_field "request.method", request.http_method
        span.add_field "request.scheme", request.endpoint.scheme
        span.add_field "request.host", request.endpoint.host
        span.add_field "request.path", request.endpoint.path
        span.add_field "request.query", request.endpoint.query
        span.add_field "request.user_agent", request.headers["user-agent"]
      end

      def handle_response(context)
        on_headers(context)
        on_error(context)
        on_done(context)
      end

      def on_headers(context)
        context.http_response.on_headers do |status_code, headers|
          span = context[:honeycomb_aws_api_span]
          span.add_field "response.status_code", status_code
          headers.each do |header, value|
            if header.start_with?("x-amz-", "x-amzn-")
              field = "response.#{header.tr('-', '_')}"
              span.add_field(field, value)
            end
          end
        end
      end

      def on_error(context)
        context.http_response.on_error do |error|
          span = context[:honeycomb_aws_api_span]
          span.add_field "response.error", error.class.name
          span.add_field "response.error_detail", error.message
        end
      end

      def on_done(context)
        context.http_response.on_done(300..599) do
          process_api_error(context)
          process_s3_region(context)
        end
      end

      def process_api_error(context)
        span = context[:honeycomb_aws_api_span]
        error = parse_api_error_from(context)
        add_api_error_fields(span, error) if error
      end

      def add_api_error_fields(span, error)
        span.add_field "response.error", error.code
        span.add_field "response.error_detail", error.message
      end

      # Runs a limited subset of response parsing for AWS-specific errors.
      #
      # Because XML/JSON error handlers are inserted at priority 50 of the
      # :sign step, they're upstream from {ApiHandler} (at priority 39), so we
      # won't have access to the error saved in Seahorse::Client::Response yet.
      # We only have the error in the Seahorse::Client::Http::Response object.
      # But Seahorse::Client::NetHttp::Handler only triggers an HTTP response
      # error for rescued exceptions (e.g., timeouts). We might still get back
      # successful HTTP 3xx, 4xx, or 5xx responses that should be interpreted
      # as aws-api errors.
      #
      # So we have to duplicate the logic of either Aws::Xml::ErrorHandler or
      # Aws::Json::ErrorHandler depending on which one is being used by the
      # current client. We can determine this by their "protocol" metadata.
      #
      # Note that there are still a few straggling errors that might occur from
      # HTTP 2xx responses. Since those aren't really API call failures, we
      # won't worry about parsing them out for the aws-api span. Once the
      # upstream handlers process those errors, they'll be propagated to the
      # aws-sdk span anyway (since {SdkHandler} will actually have access to
      # the Seahorse::Client::Response#error).
      #
      # @see https://github.com/aws/aws-sdk-ruby/blob/d0c5f6e5a3e83eeda2d1c81f5dd80e5ac562a6dc/gems/aws-sdk-core/lib/aws-sdk-core/client_stubs.rb#L298-L307
      # @see https://github.com/aws/aws-sdk-ruby/tree/b0ade445ce18b24c53a4548074b214e732b8b627/gems/aws-sdk-core/lib/aws-sdk-core/plugins/protocols
      # @see https://github.com/aws/aws-sdk-ruby/blob/354d36792e47f2e81b4889f322928e848e062818/gems/aws-sdk-s3/lib/aws-sdk-s3/plugins/http_200_errors.rb
      # @see https://github.com/aws/aws-sdk-ruby/blob/354d36792e47f2e81b4889f322928e848e062818/gems/aws-sdk-dynamodb/lib/aws-sdk-dynamodb/plugins/crc32_validation.rb
      def parse_api_error_from(context)
        case context.config.api.metadata["protocol"]
        when "query", "rest-xml", "ec2"
          XmlError.new(context)
        when "json", "rest-json"
          JsonError.new(context)
        end
      end

      # @private
      # @see https://github.com/aws/aws-sdk-ruby/blob/d0c5f6e5a3e83eeda2d1c81f5dd80e5ac562a6dc/gems/aws-sdk-core/lib/aws-sdk-core/xml/error_handler.rb
      class XmlError < ::Aws::Xml::ErrorHandler
        attr_reader :code, :message

        def initialize(context)
          body = context.http_response.body_contents
          @code = error_code(body, context)
          @message = error_message(body)
        end
      end

      # @private
      # @see https://github.com/aws/aws-sdk-ruby/blob/d0c5f6e5a3e83eeda2d1c81f5dd80e5ac562a6dc/gems/aws-sdk-core/lib/aws-sdk-core/json/error_handler.rb
      class JsonError < ::Aws::Json::ErrorHandler
        attr_reader :code, :message

        def initialize(context)
          body = context.http_response.body_contents
          json = ::Aws::Json.load(body) || {}
          @code = error_code(json, context)
          @message = error_message(code, json)
        rescue ::Aws::Json::ParseError
          @code = http_status_error_code(context)
          @message = ""
        end
      end

      # Propagates S3 region redirect information to the next aws-api span.
      #
      # When the AWS S3 client is configured with the wrong region, Amazon
      # responds to API requests with an HTTP 400 indicating the correct region
      # for the bucket.
      #
      # This error is normally caught upstream by stock plugins that trigger a
      # new API request with the right region, which will create another
      # aws-api span after this one. However, since the aws.region field set by
      # {#add_aws_api_fields} comes from the aws-sdk configuration, its value
      # would continue being wrong in the next aws-api span. Instead, we want
      # this span to have the wrong region (that triggered the error) and the
      # next span to have the right region (which won't come from the config).
      #
      # To update aws.region to the right value, {#handle_redirect} looks for a
      # value stashed in the Seahorse::Client::Context#metadata. This is set by
      # aws-sdk v3 (via the aws-sdk-s3 gem) but not by aws-sdk v2. So, we have
      # to duplicate some of the upstream v3 logic in order to propagate the
      # redirected region in the v2 case. We only do this in the v2 case in the
      # hopes that eventually we don't have to maintain the duplicated logic.
      #
      # @see https://github.com/aws/aws-sdk-ruby/blob/379d338406873b0f4b53f118c83fe40761e297ab/gems/aws-sdk-s3/lib/aws-sdk-s3/plugins/s3_signer.rb#L151
      def process_s3_region(context)
        return unless SDK_VERSION.start_with?("2.")

        redirect = S3Redirect.new(context)
        context[:redirect_region] = redirect.region if redirect.happening?
      end

      # @private
      # @see https://github.com/aws/aws-sdk-ruby/blob/379d338406873b0f4b53f118c83fe40761e297ab/gems/aws-sdk-s3/lib/aws-sdk-s3/plugins/s3_signer.rb#L102-L182
      # @see https://github.com/aws/aws-sdk-ruby/blob/4c40f6e67e763a0f392ba5b1449254426b68a600/aws-sdk-core/lib/aws-sdk-core/plugins/s3_request_signer.rb#L81-L153
      class S3Redirect
        REGION_TAG = %r{<Region>(.+?)</Region>}.freeze

        def initialize(context)
          @context = context
        end

        def original_host
          @context.http_request.endpoint.host
        end

        def status
          @context.http_response.status_code
        end

        def happening?
          status == 400 && region && !original_host.include?("fips")
        end

        def region
          @region ||= region_from_headers || region_from_body
        end

        def region_from_headers
          @context.http_response.headers["x-amz-bucket-region"]
        end

        def region_from_body
          body = @context.http_response.body_contents
          body.match(REGION_TAG) { |tag| tag[1] }
        end
      end
    end
  end
end

# Add the plugin to all aws-sdk client classes.
#
# Since client classes are dynamically created at load time by
# Seahorse::Client::Base.define, it's necessary to call .add_plugin on each
# class individually. For example, say we required aws-sdk-s3 before loading
# honeycomb-beeline. Then Aws::S3::Client would have already been defined
# without knowing about our plugin. So adding Honeycomb::Aws::Plugin to just
# Seahorse::Client::Base is insufficent. We have to call
# Aws::S3::Client.add_plugin as well.
#
# This loop will still add the plugin to Seahorse::Client::Base, which covers
# us if/when any future aws-sdk client classes get defined.
#
# This loop will *not* patch any instances of client objects that were created
# prior to loading honeycomb-beeline. While we could loop through
# ObjectSpace.each_object(Seahorse::Client::Base), it's much more awkward to
# reinitialize an existing instance. E.g., at the time the client instance was
# created, its configuration wouldn't have responded to the options defined by
# Honeycomb::Aws::Plugin, so we can't retroactively configure the plugin. In
# practice, this probably isn't a big deal: you'll likely load aws-sdk +
# honeycomb-beeline via bundler before ever instantiating an AWS client object.
ObjectSpace.each_object(Seahorse::Client::Base.singleton_class) do |client|
  client.add_plugin(Honeycomb::Aws::Plugin)
end
