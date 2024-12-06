require 'forwardable'
require 'flipper/ui/configuration'
require 'flipper/ui/error'
require 'erubi'
require 'json'
require 'sanitize'

module Flipper
  module UI
    class Action
      module FeatureNameFromRoute
        def feature_name
          @feature_name ||= begin
            match = request.path_info.match(self.class.route_regex)
            match ? Rack::Utils.unescape(match[:feature_name]) : nil
          end
        end
        private :feature_name
      end

      extend Forwardable

      VALID_REQUEST_METHOD_NAMES = Set.new([
                                             'get'.freeze,
                                             'post'.freeze,
                                             'put'.freeze,
                                             'delete'.freeze,
                                           ]).freeze

      SOURCES = {
        bootstrap_css: {
          src: 'https://cdn.jsdelivr.net/npm/bootstrap@4.6.0/dist/css/bootstrap.min.css'.freeze,
          hash: 'sha384-B0vP5xmATw1+K9KRQjQERJvTumQW0nPEzvF6L/Z6nronJ3oUOFUFpCjEUQouq2+l'.freeze
        }.freeze,
        jquery_js: {
          src: 'https://code.jquery.com/jquery-3.6.0.slim.js'.freeze,
          hash: 'sha256-HwWONEZrpuoh951cQD1ov2HUK5zA5DwJ1DNUXaM6FsY='.freeze
        }.freeze,
        popper_js: {
          src: 'https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.12.9/umd/popper.min.js'.freeze,
          hash: 'sha384-ApNbgh9B+Y1QKtv3Rn7W3mgPxhU9K/ScQsAP7hUibX39j7fakFPskvXusvfa0b4Q'.freeze
        }.freeze,
        bootstrap_js: {
          src: 'https://cdn.jsdelivr.net/npm/bootstrap@4.6.0/dist/js/bootstrap.min.js'.freeze,
          hash: 'sha384-+YQ4JLhjyBLPDQt//I+STsc9iw4uQqACwlvpslubQzn4u2UU2UFM80nGisd026JF'.freeze
        }.freeze
      }.freeze
      SCRIPT_SRCS = SOURCES.values_at(:jquery_js, :popper_js, :bootstrap_js).map { |s| s[:src] }
      STYLE_SRCS = SOURCES.values_at(:bootstrap_css).map { |s| s[:src] }
      CONTENT_SECURITY_POLICY = <<-CSP.delete("\n")
        default-src 'none';
        img-src 'self';
        font-src 'self';
        script-src 'report-sample' 'self' #{SCRIPT_SRCS.join(' ')};
        style-src 'self' 'unsafe-inline' #{STYLE_SRCS.join(' ')};
        style-src-attr 'unsafe-inline' ;
        style-src-elem 'self' #{STYLE_SRCS.join(' ')};
      CSP

      # Public: Call this in subclasses so the action knows its route.
      #
      # regex - The Regexp that this action should run for.
      #
      # Returns nothing.
      def self.route(regex)
        @route_regex = regex
      end

      # Internal: Does this action's route match the path.
      def self.route_match?(path)
        path.match(route_regex)
      end

      # Internal: The regex that matches which routes this action will work for.
      def self.route_regex
        @route_regex || raise("#{name}.route is not set")
      end

      # Internal: Initializes and runs an action for a given request.
      #
      # flipper - The Flipper::DSL instance.
      # request - The Rack::Request that was sent.
      #
      # Returns result of Action#run.
      def self.run(flipper, request)
        new(flipper, request).run
      end

      # Private: The path to the views folder.
      def self.views_path
        @views_path ||= Flipper::UI.root.join('views')
      end

      # Private: The path to the public folder.
      def self.public_path
        @public_path ||= Flipper::UI.root.join('public')
      end

      # Public: The instance of the Flipper::DSL the middleware was
      # initialized with.
      attr_reader :flipper

      # Public: The Rack::Request to provide a response for.
      attr_reader :request

      # Public: The params for the request.
      def_delegator :@request, :params

      def initialize(flipper, request)
        @flipper = flipper
        @request = request
        @code = 200
        @headers = { 'Content-Type' => 'text/plain' }
        @breadcrumbs =
          if Flipper::UI.configuration.application_breadcrumb_href
            [Breadcrumb.new('App', Flipper::UI.configuration.application_breadcrumb_href)]
          else
            []
          end
      end

      # Public: Runs the request method for the provided request.
      #
      # Returns whatever the request method returns in the action.
      def run
        if valid_request_method? && respond_to?(request_method_name)
          catch(:halt) { send(request_method_name) }
        else
          raise UI::RequestMethodNotSupported,
                "#{self.class} does not support request method #{request_method_name.inspect}"
        end
      end

      # Public: Runs another action from within the request method of a
      # different action.
      #
      # action_class - The class of the other action to run.
      #
      # Examples
      #
      #   run_other_action Home
      #   # => result of running Home action
      #
      # Returns result of other action.
      def run_other_action(action_class)
        action_class.new(flipper, request).run
      end

      # Public: Call this with a response to immediately stop the current action
      # and respond however you want.
      #
      # response - The response you would like to return.
      def halt(response)
        throw :halt, response
      end

      # Public: Compiles a view and returns rack response with that as the body.
      #
      # name - The Symbol name of the view.
      #
      # Returns a response.
      def view_response(name)
        header 'Content-Type', 'text/html'
        header 'Content-Security-Policy', CONTENT_SECURITY_POLICY
        body = view_with_layout { view_without_layout name }
        halt [@code, @headers, [body]]
      end

      # Public: Dumps an object as json and returns rack response with that as
      # the body. Automatically sets Content-Type to "application/json".
      #
      # object - The Object that should be dumped as json.
      #
      # Returns a response.
      def json_response(object)
        header 'Content-Type', 'application/json'
        body = JSON.dump(object)
        halt [@code, @headers, [body]]
      end

      # Public: Redirect to a new location.
      #
      # location - The String location to set the Location header to.
      def redirect_to(location)
        status 302
        header 'Location', "#{script_name}#{Rack::Utils.escape_path(location)}"
        halt [@code, @headers, ['']]
      end

      # Public: Set the status code for the response.
      #
      # code - The Integer code you would like the response to return.
      def status(code)
        @code = code.to_i
      end

      # Public: Set a header.
      #
      # name - The String name of the header.
      # value - The value of the header.
      def header(name, value)
        @headers[name] = value
      end

      class Breadcrumb
        attr_reader :text, :href

        def initialize(text, href = nil)
          @text = text
          @href = href
        end

        def active?
          @href.nil?
        end
      end

      # Public: Add a breadcrumb to the trail.
      #
      # text - The String text for the breadcrumb.
      # href - The String href for the anchor tag (optional). If nil, breadcrumb
      #        is assumed to be the end of the trail.
      def breadcrumb(text, href = nil)
        breadcrumb_href = href.nil? ? href : "#{script_name}#{href}"
        @breadcrumbs << Breadcrumb.new(text, breadcrumb_href)
      end

      # Private
      def view_with_layout(&block)
        view :layout, &block
      end

      # Private
      def view_without_layout(name)
        view name
      end

      # Private
      def view(name)
        path = views_path.join("#{name}.erb")
        raise "Template does not exist: #{path}" unless path.exist?

        eval(Erubi::Engine.new(path.read, escape: true).src)
      end

      # Internal: The path the app is mounted at.
      def script_name
        request.env['SCRIPT_NAME']
      end

      # Private
      def views_path
        self.class.views_path
      end

      # Private
      def public_path
        self.class.public_path
      end

      # Private: Returns the request method converted to an action method.
      def request_method_name
        @request_method_name ||= @request.request_method.downcase
      end

      def csrf_input_tag
        %(<input type="hidden" name="authenticity_token" value="#{@request.session[:csrf]}">)
      end

      def valid_request_method?
        VALID_REQUEST_METHOD_NAMES.include?(request_method_name)
      end

      # Internal: Method to call when the UI is in read only mode and you want
      # to inform people of that fact.
      def read_only
        status 403

        breadcrumb 'Home', '/'
        breadcrumb 'Features', '/features'
        breadcrumb 'Noooooope'

        halt view_response(:read_only)
      end

      def bootstrap_css
        SOURCES[:bootstrap_css]
      end

      def bootstrap_js
        SOURCES[:bootstrap_js]
      end

      def popper_js
        SOURCES[:popper_js]
      end

      def jquery_js
        SOURCES[:jquery_js]
      end
    end
  end
end
