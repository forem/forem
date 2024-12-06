module VCR
  module Middleware
    # Object yielded by VCR's {Rack} middleware that allows you to configure
    # the cassette dynamically based on the rack env.
    class CassetteArguments
      # @private
      def initialize
        @name    = nil
        @options = {}
      end

      # Sets (and gets) the cassette name.
      #
      # @param [#to_s] name the cassette name
      # @return [#to_s] the cassette name
      def name(name = nil)
        @name = name if name
        @name
      end

      # Sets (and gets) the cassette options.
      #
      # @param [Hash] options the cassette options
      # @return [Hash] the cassette options
      def options(options = {})
        @options.merge!(options)
      end
    end

    # Rack middleware that uses a VCR cassette for each incoming HTTP request.
    #
    # @example
    #   app = Rack::Builder.new do
    #     use VCR::Middleware::Rack do |cassette, env|
    #       cassette.name "rack/#{env['SERVER_NAME']}"
    #       cassette.options :record => :new_episodes
    #     end
    #
    #     run MyRackApp
    #   end
    #
    # @note This will record/replay _outbound_ HTTP requests made by your rack app.
    class Rack
      include VCR::VariableArgsBlockCaller

      # Constructs a new instance of VCR's rack middleware.
      #
      # @param [#call] app the rack app
      # @yield the cassette configuration block
      # @yieldparam [CassetteArguments] cassette the cassette configuration object
      # @yieldparam [(optional) Hash] env the rack env hash
      # @raise [ArgumentError] if no configuration block is provided
      def initialize(app, &block)
        raise ArgumentError.new("You must provide a block to set the cassette options") unless block
        @app, @cassette_arguments_block, @mutex = app, block, Mutex.new
      end

      # Implements the rack middleware interface.
      #
      # @param [Hash] env the rack env hash
      # @return [Array(Integer, Hash, #each)] the rack response
      def call(env)
        @mutex.synchronize do
          VCR.use_cassette(*cassette_arguments(env)) do
            @app.call(env)
          end
        end
      end

    private

      def cassette_arguments(env)
        arguments = CassetteArguments.new
        call_block(@cassette_arguments_block, arguments, env)
        [arguments.name, arguments.options]
      end
    end
  end
end
