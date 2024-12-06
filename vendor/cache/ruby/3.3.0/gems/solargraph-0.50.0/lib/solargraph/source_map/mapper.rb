# frozen_string_literal: true

module Solargraph
  class SourceMap
    # The Mapper generates pins and other data for SourceMaps.
    #
    # This class is used internally by the SourceMap class. Users should not
    # normally need to call it directly.
    #
    class Mapper
      # include Source::NodeMethods

      private_class_method :new

      DIRECTIVE_REGEXP = /(@\!method|@\!attribute|@\!visibility|@\!domain|@\!macro|@\!parse|@\!override)/.freeze

      # Generate the data.
      #
      # @param source [Source]
      # @return [Array]
      def map source
        @source = source
        @filename = source.filename
        @code = source.code
        @comments = source.comments
        @pins, @locals = Parser.map(source)
        @pins.each { |p| p.source = :code }
        @locals.each { |l| l.source = :code }
        process_comment_directives
        [@pins, @locals]
      # rescue Exception => e
      #   Solargraph.logger.warn "Error mapping #{source.filename}: [#{e.class}] #{e.message}"
      #   Solargraph.logger.warn e.backtrace.join("\n")
      #   [[], []]
      end

      # @param filename [String]
      # @param code [String]
      # @return [Array]
      def unmap filename, code
        s = Position.new(0, 0)
        e = Position.from_offset(code, code.length)
        location = Location.new(filename, Range.new(s, e))
        [[Pin::Namespace.new(location: location, name: '')], []]
      end

      class << self
        # @param source [Source]
        # @return [Array]
        def map source
          return new.unmap(source.filename, source.code) unless source.parsed?
          new.map source
        end
      end

      # @return [Array<Solargraph::Pin::Base>]
      def pins
        @pins ||= []
      end

      # @param position [Solargraph::Position]
      # @return [Solargraph::Pin::Closure]
      def closure_at(position)
        pins.select{|pin| pin.is_a?(Pin::Closure) and pin.location.range.contain?(position)}.last
      end

      def process_comment source_position, comment_position, comment
        return unless comment.encode('UTF-8', invalid: :replace, replace: '?') =~ DIRECTIVE_REGEXP
        cmnt = remove_inline_comment_hashes(comment)
        parse = Solargraph::Source.parse_docstring(cmnt)
        last_line = 0
        # @param d [YARD::Tags::Directive]
        parse.directives.each do |d|
          line_num = find_directive_line_number(cmnt, d.tag.tag_name, last_line)
          pos = Solargraph::Position.new(comment_position.line + line_num - 1, comment_position.column)
          process_directive(source_position, pos, d)
          last_line = line_num + 1
        end
      end

      # @param comment [String]
      # @return [Integer]
      def find_directive_line_number comment, tag, start
        # Avoid overruning the index
        return start unless start < comment.lines.length
        num = comment.lines[start..-1].find_index do |line|
          # Legacy method directives might be `@method` instead of `@!method`
          # @todo Legacy syntax should probably emit a warning
          line.include?("@!#{tag}") || (tag == 'method' && line.include?("@#{tag}"))
        end
        num.to_i + start
      end

      # @param source_position [Position]
      # @param comment_position [Position]
      # @param directive [YARD::Tags::Directive]
      # @return [void]
      def process_directive source_position, comment_position, directive
        docstring = Solargraph::Source.parse_docstring(directive.tag.text).to_docstring
        location = Location.new(@filename, Range.new(comment_position, comment_position))
        case directive.tag.tag_name
        when 'method'
          namespace = closure_at(source_position) || @pins.first
          if namespace.location.range.start.line < comment_position.line
            namespace = closure_at(comment_position)
          end
          begin
            src = Solargraph::Source.load_string("def #{directive.tag.name};end", @source.filename)
            region = Parser::Region.new(source: src, closure: namespace)
            gen_pin = Parser.process_node(src.node, region).first.last
            return if gen_pin.nil?
            # Move the location to the end of the line so it gets recognized
            # as originating from a comment
            shifted = Solargraph::Position.new(comment_position.line, @code.lines[comment_position.line].to_s.chomp.length)
            # @todo: Smelly instance variable access
            gen_pin.instance_variable_set(:@comments, docstring.all.to_s)
            gen_pin.instance_variable_set(:@location, Solargraph::Location.new(@filename, Range.new(shifted, shifted)))
            gen_pin.instance_variable_set(:@explicit, false)
            @pins.push gen_pin
          rescue Parser::SyntaxError => e
            # @todo Handle error in directive
          end
        when 'attribute'
          return if directive.tag.name.nil?
          namespace = closure_at(source_position)
          t = (directive.tag.types.nil? || directive.tag.types.empty?) ? nil : directive.tag.types.flatten.join('')
          if t.nil? || t.include?('r')
            pins.push Solargraph::Pin::Method.new(
              location: location,
              closure: namespace,
              name: directive.tag.name,
              comments: docstring.all.to_s,
              scope: namespace.is_a?(Pin::Singleton) ? :class : :instance,
              visibility: :public,
              explicit: false,
              attribute: true
            )
          end
          if t.nil? || t.include?('w')
            pins.push Solargraph::Pin::Method.new(
              location: location,
              closure: namespace,
              name: "#{directive.tag.name}=",
              comments: docstring.all.to_s,
              scope: namespace.is_a?(Pin::Singleton) ? :class : :instance,
              visibility: :public,
              attribute: true
            )
            pins.last.parameters.push Pin::Parameter.new(name: 'value', decl: :arg, closure: pins.last)
            if pins.last.return_type.defined?
              pins.last.docstring.add_tag YARD::Tags::Tag.new(:param, '', pins.last.return_type.to_s.split(', '), 'value')
            end
          end
        when 'visibility'
          begin
            kind = directive.tag.text&.to_sym
            return unless [:private, :protected, :public].include?(kind)

            name = directive.tag.name
            closure = closure_at(source_position) || @pins.first
            if closure.location.range.start.line < comment_position.line
              closure = closure_at(comment_position)
            end
            if closure.is_a?(Pin::Method) && no_empty_lines?(comment_position.line, source_position.line)
              # @todo Smelly instance variable access
              closure.instance_variable_set(:@visibility, kind)
            else
              matches = pins.select{ |pin| pin.is_a?(Pin::Method) && pin.name == name && pin.namespace == namespace && pin.context.scope == namespace.is_a?(Pin::Singleton) ? :class : :instance }
              matches.each do |pin|
                # @todo Smelly instance variable access
                pin.instance_variable_set(:@visibility, kind)
              end
            end
          end
        when 'parse'
          begin
            ns = closure_at(source_position)
            src = Solargraph::Source.load_string(directive.tag.text, @source.filename)
            region = Parser::Region.new(source: src, closure: ns)
            # @todo These pins may need to be marked not explicit
            index = @pins.length
            loff = if @code.lines[comment_position.line].strip.end_with?('@!parse')
              comment_position.line + 1
            else
              comment_position.line
            end
            Parser.process_node(src.node, region, @pins)
            @pins[index..-1].each do |p|
              # @todo Smelly instance variable access
              p.location.range.start.instance_variable_set(:@line, p.location.range.start.line + loff)
              p.location.range.ending.instance_variable_set(:@line, p.location.range.ending.line + loff)
            end
          rescue Parser::SyntaxError => e
            # @todo Handle parser errors in !parse directives
          end
        when 'domain'
          namespace = closure_at(source_position) || Pin::ROOT_PIN
          namespace.domains.concat directive.tag.types unless directive.tag.types.nil?
        when 'override'
          pins.push Pin::Reference::Override.new(location, directive.tag.name, docstring.tags)
        when 'macro'
          # @todo Handle macros
        end
      end

      def no_empty_lines?(line1, line2)
        @code.lines[line1..line2].none? { |line| line.strip.empty? }
      end

      def remove_inline_comment_hashes comment
        ctxt = ''
        num = nil
        started = false
        comment.lines.each { |l|
          # Trim the comment and minimum leading whitespace
          p = l.encode('UTF-8', invalid: :replace, replace: '?').gsub(/^#+/, '')
          if num.nil? && !p.strip.empty?
            num = p.index(/[^ ]/)
            started = true
          elsif started && !p.strip.empty?
            cur = p.index(/[^ ]/)
            num = cur if cur < num
          end
          ctxt += "#{p[num..-1]}" if started
        }
        ctxt
      end

      # @return [void]
      def process_comment_directives
        return unless @code.encode('UTF-8', invalid: :replace, replace: '?') =~ DIRECTIVE_REGEXP
        code_lines = @code.lines
        @source.associated_comments.each do |line, comments|
          src_pos = line ? Position.new(line, code_lines[line].to_s.chomp.index(/[^\s]/) || 0) : Position.new(code_lines.length, 0)
          com_pos = Position.new(line + 1 - comments.lines.length, 0)
          process_comment(src_pos, com_pos, comments)
        end
      rescue StandardError => e
        raise e.class, "Error processing comment directives in #{@filename}: #{e.message}"
      end
    end
  end
end
