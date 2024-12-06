module JsRoutes
  class Route #:nodoc:
    FILTERED_DEFAULT_PARTS = [:controller, :action]
    URL_OPTIONS = [:protocol, :domain, :host, :port, :subdomain]
    NODE_TYPES = {
      GROUP: 1,
      CAT: 2,
      SYMBOL: 3,
      OR: 4,
      STAR: 5,
      LITERAL: 6,
      SLASH: 7,
      DOT: 8
    }

    attr_reader :configuration, :route, :parent_route

    def initialize(configuration, route, parent_route = nil)
      @configuration = configuration
      @route = route
      @parent_route = parent_route
    end

    def helpers
      helper_types.map do |absolute|
        [ documentation, helper_name(absolute), body(absolute) ]
      end
    end

    def helper_types
      return [] unless match_configuration?
      @configuration[:url_links] ? [true, false] : [false]
    end

    def body(absolute)
      if @configuration.dts?
        definition_body
      else
        # For tree-shaking ESM, add a #__PURE__ comment informing Webpack/minifiers that the call to `__jsr.r`
        # has no side-effects (e.g. modifying global variables) and is safe to remove when unused.
        # https://webpack.js.org/guides/tree-shaking/#clarifying-tree-shaking-and-sideeffects
        pure_comment = @configuration.esm? ? '/*#__PURE__*/ ' : ''
        "#{pure_comment}__jsr.r(#{arguments(absolute).map{|a| json(a)}.join(', ')})"
      end
    end

    def definition_body
      args = required_parts.map{|p| "#{apply_case(p)}: RequiredRouteParameter"}
      args << "options?: #{optional_parts_type} & RouteOptions"
      "((\n#{args.join(",\n").indent(2)}\n) => string) & RouteHelperExtras"
    end

    def optional_parts_type
      @optional_parts_type ||=
        "{" + optional_parts.map {|p| "#{p}?: OptionalRouteParameter"}.join(', ') + "}"
    end

    protected

    def arguments(absolute)
      absolute ? [*base_arguments, true] : base_arguments
    end

    def match_configuration?
      !match?(@configuration[:exclude]) && match?(@configuration[:include])
    end

    def base_name
      @base_name ||= parent_route ?
        [parent_route.name, route.name].join('_') : route.name
    end

    def parent_spec
      parent_route&.path&.spec
    end

    def spec
      route.path.spec
    end

    def json(value)
      JsRoutes.json(value)
    end

    def helper_name(absolute)
      suffix = absolute ? :url : @configuration[:compact] ? nil : :path
      apply_case(base_name, suffix)
    end

    def documentation
      return nil unless @configuration[:documentation]
      <<-JS
/**
 * Generates rails route to
 * #{parent_spec}#{spec}#{documentation_params}
 * @param {object | undefined} options
 * @returns {string} route path
 */
JS
    end

    def required_parts
      route.required_parts
    end

    def optional_parts
      route.path.optional_names
    end

    def base_arguments
      @base_arguments ||= [parts_table, serialize(spec, parent_spec)]
    end

    def parts_table
      parts_table = {}
      route.parts.each do |part, hash|
        parts_table[part] ||= {}
        if required_parts.include?(part)
          # Using shortened keys to reduce js file size
          parts_table[part][:r] = true
        end
      end
      route.defaults.each do |part, value|
        if FILTERED_DEFAULT_PARTS.exclude?(part) &&
          URL_OPTIONS.include?(part) || parts_table[part]
          parts_table[part] ||= {}
          # Using shortened keys to reduce js file size
          parts_table[part][:d] = value
        end
      end
      parts_table
    end

    def documentation_params
      required_parts.map do |param|
        "\n * @param {any} #{apply_case(param)}"
      end.join
    end

    def match?(matchers)
      Array(matchers).any? { |regex| base_name =~ regex }
    end

    def apply_case(*values)
      value = values.compact.map(&:to_s).join('_')
      @configuration[:camel_case] ? value.camelize(:lower) : value
    end

    # This function serializes Journey route into JSON structure
    # We do not use Hash for human readable serialization
    # And preffer Array serialization because it is shorter.
    # Routes.js file will be smaller.
    def serialize(spec, parent_spec=nil)
      return nil unless spec
      # Rails 4 globbing requires * removal
      return spec.tr(':*', '') if spec.is_a?(String)

      result = serialize_spec(spec, parent_spec)
      if parent_spec && result[1].is_a?(String) && parent_spec.type != :SLASH
        result = [
          # We encode node symbols as integer
          # to reduce the routes.js file size
          NODE_TYPES[:CAT],
          serialize_spec(parent_spec),
          result
        ]
      end
      result
    end

    def serialize_spec(spec, parent_spec = nil)
      [
        NODE_TYPES[spec.type],
        serialize(spec.left, parent_spec),
        spec.respond_to?(:right) ? serialize(spec.right) : nil
      ].compact
    end
  end
end
