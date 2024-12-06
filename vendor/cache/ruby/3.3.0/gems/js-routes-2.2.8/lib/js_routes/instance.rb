require "js_routes/configuration"
require "js_routes/route"

module JsRoutes
  class Instance # :nodoc:

    attr_reader :configuration
    #
    # Implementation
    #

    def initialize(options = {})
      @configuration = JsRoutes.configuration.merge(options)
    end

    def generate
      # Ensure routes are loaded. If they're not, load them.
      if named_routes.empty? && application.respond_to?(:reload_routes!)
        application.reload_routes!
      end
      content = File.read(@configuration.source_file)

      if !@configuration.dts?
        content = js_variables.inject(content) do |js, (key, value)|
          js.gsub!("RubyVariables.#{key}", value.to_s) ||
          raise("Missing key #{key} in JS template")
        end
      end
      content + routes_export + prevent_types_export
    end

    def generate!
      # Some libraries like Devise did not load their routes yet
      # so we will wait until initialization process finishes
      # https://github.com/railsware/js-routes/issues/7
      Rails.configuration.after_initialize do
        file_path = Rails.root.join(@configuration.output_file)
        source_code = generate

        # We don't need to rewrite file if it already exist and have same content.
        # It helps asset pipeline or webpack understand that file wasn't changed.
        next if File.exist?(file_path) && File.read(file_path) == source_code

        File.open(file_path, 'w') do |f|
          f.write source_code
        end
      end
    end

    protected

    def js_variables
      {
        'GEM_VERSION'         => JsRoutes::VERSION,
        'ROUTES_OBJECT'       => routes_object,
        'RAILS_VERSION'       => ActionPack.version,
        'DEPRECATED_GLOBBING_BEHAVIOR' => ActionPack::VERSION::MAJOR == 4 && ActionPack::VERSION::MINOR == 0,
        'DEPRECATED_FALSE_PARAMETER_BEHAVIOR' => ActionPack::VERSION::MAJOR < 7,
        'APP_CLASS'           => application.class.to_s,
        'DEFAULT_URL_OPTIONS' => json(@configuration.default_url_options),
        'PREFIX'              => json(@configuration.prefix),
        'SPECIAL_OPTIONS_KEY' => json(@configuration.special_options_key),
        'SERIALIZER'          => @configuration.serializer || json(nil),
        'MODULE_TYPE'         => json(@configuration.module_type),
        'WRAPPER'             => wrapper_variable,
      }
    end

    def wrapper_variable
      case @configuration.module_type
      when 'ESM'
        'const __jsr = '
      when 'NIL'
        namespace = @configuration.namespace
        if namespace
          if namespace.include?('.')
            "#{namespace} = "
          else
            "(typeof window !== 'undefined' ? window : this).#{namespace} = "
          end
        else
          ''
        end
      else
        ''
      end
    end

    def application
      @configuration.application
    end

    def json(string)
      JsRoutes.json(string)
    end

    def named_routes
      application.routes.named_routes.to_a
    end

    def routes_object
      return json({}) if @configuration.modern?
      properties = routes_list.map do |comment, name, body|
        "#{comment}#{name}: #{body}".indent(2)
      end
      "{\n" + properties.join(",\n\n") + "}\n"
    end

    def static_exports
      [:configure, :config, :serialize].map do |name|
        [
          "", name,
          @configuration.dts? ?
          "RouterExposedMethods['#{name}']" :
          "__jsr.#{name}"
        ]
      end
    end

    def routes_export
      return "" unless @configuration.modern?
      [*static_exports, *routes_list].map do |comment, name, body|
        "#{comment}export const #{name}#{export_separator}#{body};\n\n"
      end.join
    end

    def prevent_types_export
      return "" unless @configuration.dts?
      <<-JS
// By some reason this line prevents all types in a file
// from being automatically exported
export {};
      JS
    end

    def export_separator
      @configuration.dts? ? ': ' : ' = '
    end

    def routes_list
      named_routes.sort_by(&:first).flat_map do |_, route|
        route_helpers_if_match(route) + mounted_app_routes(route)
      end
    end

    def mounted_app_routes(route)
      rails_engine_app = app_from_route(route)
      if rails_engine_app.respond_to?(:superclass) &&
          rails_engine_app.superclass == Rails::Engine && !route.path.anchored
        rails_engine_app.routes.named_routes.flat_map do |_, engine_route|
          route_helpers_if_match(engine_route, route)
        end
      else
        []
      end
    end

    def app_from_route(route)
      app = route.app
      # rails engine in Rails 4.2 use additional
      # ActionDispatch::Routing::Mapper::Constraints, which contain app
      if app.respond_to?(:app) && app.respond_to?(:constraints)
        app.app
      else
        app
      end
    end

    def route_helpers_if_match(route, parent_route = nil)
      Route.new(@configuration, route, parent_route).helpers
    end
  end
end
