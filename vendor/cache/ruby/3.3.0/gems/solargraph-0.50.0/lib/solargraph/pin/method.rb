# frozen_string_literal: true

module Solargraph
  module Pin
    # The base class for method and attribute pins.
    #
    class Method < Closure
      include Solargraph::Parser::NodeMethods

      # @return [Array<Pin::Parameter>]
      attr_reader :parameters

      # @return [::Symbol] :public, :private, or :protected
      attr_reader :visibility

      # @return [Parser::AST::Node]
      attr_reader :node

      # @param visibility [::Symbol] :public, :protected, or :private
      # @param explicit [Boolean]
      # @param parameters [Array<Pin::Parameter>]
      # @param node [Parser::AST::Node, RubyVM::AbstractSyntaxTree::Node]
      # @param attribute [Boolean]
      def initialize visibility: :public, explicit: true, parameters: [], node: nil, attribute: false, signatures: nil, anon_splat: false, **splat
        super(**splat)
        @visibility = visibility
        @explicit = explicit
        @parameters = parameters
        @node = node
        @attribute = attribute
        @signatures = signatures
        @anon_splat = anon_splat
      end

      # @return [Array<String>]
      def parameter_names
        @parameter_names ||= parameters.map(&:name)
      end

      def completion_item_kind
        attribute? ? Solargraph::LanguageServer::CompletionItemKinds::PROPERTY : Solargraph::LanguageServer::CompletionItemKinds::METHOD
      end

      def symbol_kind
        attribute? ? Solargraph::LanguageServer::SymbolKinds::PROPERTY : LanguageServer::SymbolKinds::METHOD
      end

      def return_type
        @return_type ||= ComplexType.try_parse(*signatures.map(&:return_type).map(&:to_s))
      end

      # @return [Array<Signature>]
      def signatures
        @signatures ||= begin
          top_type = generate_complex_type
          result = []
          result.push Signature.new(parameters, top_type) if top_type.defined?
          result.concat(overloads.map { |meth| Signature.new(meth.parameters, meth.return_type) })
          result.push Signature.new(parameters, top_type) if result.empty?
          result
        end
      end

      # @return [String]
      def detail
        # This property is not cached in an instance variable because it can
        # change when pins get proxied.
        detail = String.new
        detail += if signatures.length > 1
          "(*) "
        else
          "(#{signatures.first.parameters.map(&:full).join(', ')}) " unless signatures.first.parameters.empty?
        end.to_s
        detail += "=#{probed? ? '~' : (proxied? ? '^' : '>')} #{return_type.to_s}" unless return_type.undefined?
        detail.strip!
        return nil if detail.empty?
        detail
      end

      # @return [Array<Hash>]
      def signature_help
        @signature_help ||= signatures.map do |sig|
          {
            label: name + '(' + sig.parameters.map(&:full).join(', ') + ')',
            documentation: documentation
          }
        end
      end

      def path
        @path ||= "#{namespace}#{(scope == :instance ? '#' : '.')}#{name}"
      end

      def typify api_map
        decl = super
        return decl unless decl.undefined?
        type = see_reference(api_map) || typify_from_super(api_map)
        return type.qualify(api_map, namespace) unless type.nil?
        name.end_with?('?') ? ComplexType::BOOLEAN : ComplexType::UNDEFINED
      end

      def documentation
        if @documentation.nil?
          @documentation ||= super || ''
          param_tags = docstring.tags(:param)
          unless param_tags.nil? or param_tags.empty?
            @documentation += "\n\n" unless @documentation.empty?
            @documentation += "Params:\n"
            lines = []
            param_tags.each do |p|
              l = "* #{p.name}"
              l += " [#{escape_brackets(p.types.join(', '))}]" unless p.types.nil? or p.types.empty?
              l += " #{p.text}"
              lines.push l
            end
            @documentation += lines.join("\n")
          end
          return_tags = docstring.tags(:return)
          unless return_tags.empty?
            @documentation += "\n\n" unless @documentation.empty?
            @documentation += "Returns:\n"
            lines = []
            return_tags.each do |r|
              l = "*"
              l += " [#{escape_brackets(r.types.join(', '))}]" unless r.types.nil? or r.types.empty?
              l += " #{r.text}"
              lines.push l
            end
            @documentation += lines.join("\n")
          end
          @documentation += "\n\n" unless @documentation.empty?
          @documentation += "Visibility: #{visibility}"
        end
        @documentation.to_s
      end

      def explicit?
        @explicit
      end

      def attribute?
        @attribute
      end

      def nearly? other
        return false unless super
        parameters == other.parameters and
          scope == other.scope and
          visibility == other.visibility
      end

      def probe api_map
        attribute? ? infer_from_iv(api_map) : infer_from_return_nodes(api_map)
      end

      def try_merge! pin
        return false unless super
        @node = pin.node
        true
      end

      # @return [Array<Pin::Method>]
      def overloads
        @overloads ||= docstring.tags(:overload).map do |tag|
          Pin::Signature.new(
            tag.parameters.map do |src|
              name, decl = parse_overload_param(src.first)
              Pin::Parameter.new(
                location: location,
                closure: self,
                comments: tag.docstring.all.to_s,
                name: name,
                decl: decl,
                presence: location ? location.range : nil,
                return_type: param_type_from_name(tag, src.first)
              )
            end,
            ComplexType.try_parse(*tag.docstring.tags(:return).flat_map(&:types))
          )
        end
        @overloads
      end

      def anon_splat?
        @anon_splat
      end

      private

      def select_decl name, asgn
        if name.start_with?('**')
          :kwrestarg
        elsif name.start_with?('*')
          :restarg
        elsif name.start_with?('&')
          :blockarg
        elsif name.end_with?(':') && asgn
          :kwoptarg
        elsif name.end_with?(':')
          :kwarg
        elsif asgn
          :optarg
        else
          :arg
        end
      end

      def clean_param name
        name.gsub(/[*&:]/, '')
      end

      # @param tag [YARD::Tags::OverloadTag]
      def param_type_from_name(tag, name)
        param = tag.tags(:param).select { |t| t.name == name }.first
        return ComplexType::UNDEFINED unless param
        ComplexType.try_parse(*param.types)
      end

      # @return [ComplexType]
      def generate_complex_type
        tags = docstring.tags(:return).map(&:types).flatten.reject(&:nil?)
        return ComplexType::UNDEFINED if tags.empty?
        ComplexType.try_parse *tags
      end

      # @param api_map [ApiMap]
      # @return [ComplexType, nil]
      def see_reference api_map
        docstring.ref_tags.each do |ref|
          next unless ref.tag_name == 'return' && ref.owner
          result = resolve_reference(ref.owner.to_s, api_map)
          return result unless result.nil?
        end
        match = comments.match(/^[ \t]*\(see (.*)\)/m)
        return nil if match.nil?
        resolve_reference match[1], api_map
      end

      # @param api_map [ApiMap]
      # @return [ComplexType, nil]
      def typify_from_super api_map
        stack = api_map.get_method_stack(namespace, name, scope: scope).reject { |pin| pin.path == path }
        return nil if stack.empty?
        stack.each do |pin|
          return pin.return_type unless pin.return_type.undefined?
        end
        nil
      end

      # @param ref [String]
      # @param api_map [ApiMap]
      # @return [ComplexType]
      def resolve_reference ref, api_map
        parts = ref.split(/[\.#]/)
        if parts.first.empty? || parts.one?
          path = "#{namespace}#{ref}"
        else
          fqns = api_map.qualify(parts.first, namespace)
          return ComplexType::UNDEFINED if fqns.nil?
          path = fqns + ref[parts.first.length] + parts.last
        end
        pins = api_map.get_path_pins(path)
        pins.each do |pin|
          type = pin.typify(api_map)
          return type unless type.undefined?
        end
        nil
      end

      # @return [Parser::AST::Node, nil]
      def method_body_node
        return nil if node.nil?
        return node.children[1].children.last if node.type == :DEFN
        return node.children[2].children.last if node.type == :DEFS
        return node.children[2] if node.type == :def || node.type == :DEFS
        return node.children[3] if node.type == :defs
        nil
      end

      # @param api_map [ApiMap]
      # @return [ComplexType]
      def infer_from_return_nodes api_map
        return ComplexType::UNDEFINED if node.nil?
        result = []
        has_nil = false
        return ComplexType::NIL if method_body_node.nil?
        returns_from(method_body_node).each do |n|
          if n.nil? || [:NIL, :nil].include?(n.type)
            has_nil = true
            next
          end
          rng = Range.from_node(n)
          next unless rng
          clip = api_map.clip_at(
            location.filename,
            rng.ending
          )
          chain = Solargraph::Parser.chain(n, location.filename)
          type = chain.infer(api_map, self, clip.locals)
          result.push type unless type.undefined?
        end
        result.push ComplexType::NIL if has_nil
        return ComplexType::UNDEFINED if result.empty?
        ComplexType.try_parse(*result.map(&:tag).uniq)
      end

      def infer_from_iv api_map
        types = []
        varname = "@#{name.gsub(/=$/, '')}"
        pins = api_map.get_instance_variable_pins(binder.namespace, binder.scope).select { |iv| iv.name == varname }
        pins.each do |pin|
          type = pin.typify(api_map)
          type = pin.probe(api_map) if type.undefined?
          types.push type if type.defined?
        end
        return ComplexType::UNDEFINED if types.empty?
        ComplexType.try_parse(*types.map(&:tag).uniq)
      end

      # When YARD parses an overload tag, it includes rest modifiers in the parameters names.
      #
      # @param arg [String]
      # @return [Array(String, Symbol)]
      def parse_overload_param(name)
        if name.start_with?('**')
          [name[2..-1], :kwrestarg]
        elsif name.start_with?('*')
          [name[1..-1], :restarg]
        else
          [name, :arg]
        end
      end
    end
  end
end
