require 'erb'
require 'uri'
require 'forwardable'

begin
  require 'i18n'
rescue LoadError
  module Honeybadger
    module I18n
      def self.t(key, options={})
        options[:default]
      end
    end
  end
end

module Honeybadger
  module Rack
    # Middleware for Rack applications. Adds a feedback form to the Rack
    # response when an error has occurred.
    class UserFeedback
      extend Forwardable

      def initialize(app, agent = nil)
        @app = app
        @agent = agent.kind_of?(Agent) && agent
      end

      def call(env)
        return @app.call(env) unless config[:'feedback.enabled']
        status, headers, body = @app.call(env)
        if env['honeybadger.error_id'] && form = render_form(env['honeybadger.error_id'])
          new_body = []
          body.each do |chunk|
            new_body << chunk.gsub("<!-- HONEYBADGER FEEDBACK -->", form)
          end
          body.close if body.respond_to?(:close)
          headers['Content-Length'] = new_body.reduce(0) { |a,e| a += e.bytesize }.to_s
          body = new_body
        end
        [status, headers, body]
      end

      # @private
      # @todo Make this method and others actually private.
      def action
        URI.parse("#{config.connection_protocol}://#{config[:'connection.host']}:#{config.connection_port}/v1/feedback/").to_s
      rescue URI::InvalidURIError
        nil
      end

      # @private
      def render_form(error_id, action = action())
        return unless action
        ERB.new(@template ||= File.read(template_file)).result(binding)
      end

      # @private
      def custom_template_file
        @custom_template_file ||= File.join(config[:root], 'lib', 'honeybadger', 'templates', 'feedback_form.erb')
      end

      # @private
      def custom_template_file?
        custom_template_file && File.exist?(custom_template_file)
      end

      # @private
      def template_file
        if custom_template_file?
          custom_template_file
        else
          File.expand_path('../../templates/feedback_form.erb', __FILE__)
        end
      end

      private

      def_delegator :agent, :config
      def_delegator :config, :logger

      def agent
        @agent || Honeybadger::Agent.instance
      end

    end
  end
end
