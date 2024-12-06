# frozen_string_literal: true

module Solargraph
  class Source
    # Information about a location in a source, including the location's word
    # and signature, literal values at the base of signatures, and whether the
    # location is inside a string or comment. ApiMaps use Fragments to provide
    # results for completion and definition queries.
    #
    class SourceChainer
      # include Source::NodeMethods

      private_class_method :new

      class << self
        # @param source [Source]
        # @param position [Position]
        # @return [Source::Chain]
        def chain source, position
          new(source, position).chain
        end
      end

      # @param source [Source]
      # @param position [Position]
      def initialize source, position
        @source = source
        @position = position
        @calculated_literal = false
      end

      # @return [Source::Chain]
      def chain
        # Special handling for files that end with an integer and a period
        return Chain.new([Chain::Literal.new('Integer'), Chain::UNDEFINED_CALL]) if phrase =~ /^[0-9]+\.$/
        return Chain.new([Chain::Literal.new('Symbol')]) if phrase.start_with?(':') && !phrase.start_with?('::')
        return SourceChainer.chain(source, Position.new(position.line, position.character + 1)) if end_of_phrase.strip == '::' && source.code[Position.to_offset(source.code, position)].to_s.match?(/[a-z]/i)
        begin
          return Chain.new([]) if phrase.end_with?('..')
          node = nil
          parent = nil
          if !source.repaired? && source.parsed? && source.synchronized?
            tree = source.tree_at(position.line, position.column)
            # node, parent = source.tree_at(position.line, position.column)[0..2]
            tree.shift while tree.length > 1 && tree.first.type == :SCOPE
            node, parent = tree[0..2]
          elsif source.parsed? && source.repaired? && end_of_phrase == '.'
            node, parent = source.tree_at(fixed_position.line, fixed_position.column)[0..2]
            node = Parser.parse(fixed_phrase) if node.nil?
          else
            node, parent = source.tree_at(fixed_position.line, fixed_position.column)[0..2] unless source.error_ranges.any?{|r| r.nil? || r.include?(fixed_position)}
            # Exception for positions that chain literal nodes in unsynchronized sources
            node = nil unless source.synchronized? || !Parser.infer_literal_node_type(node).nil?
            node = Parser.parse(fixed_phrase) if node.nil?
          end
        rescue Parser::SyntaxError
          return Chain.new([Chain::UNDEFINED_CALL])
        end
        return Chain.new([Chain::UNDEFINED_CALL]) if node.nil? || (node.type == :sym && !phrase.start_with?(':'))
        # chain = NodeChainer.chain(node, source.filename, parent && parent.type == :block)
        chain = Parser.chain(node, source.filename, parent && [:ITER, :block].include?(parent.type))
        if source.repaired? || !source.parsed? || !source.synchronized?
          if end_of_phrase.strip == '.'
            chain.links.push Chain::UNDEFINED_CALL
          elsif end_of_phrase.strip == '::'
            chain.links.push Chain::UNDEFINED_CONSTANT
          end
        elsif chain.links.last.is_a?(Source::Chain::Constant) && end_of_phrase.strip == '::'
          chain.links.push Source::Chain::UNDEFINED_CONSTANT
        end
        chain
      end

      private

      # @return [Position]
      attr_reader :position

      # @return [Solargraph::Source]
      attr_reader :source

      # @return [String]
      def phrase
        @phrase ||= source.code[signature_data..offset-1]
      end

      # @return [String]
      def fixed_phrase
        @fixed_phrase ||= phrase[0..-(end_of_phrase.length+1)]
      end

      # @return [Position]
      def fixed_position
        @fixed_position ||= Position.from_offset(source.code, offset - end_of_phrase.length)
      end

      # @return [String]
      def end_of_phrase
        @end_of_phrase ||= begin
          match = phrase.match(/[\s]*(\.{1}|::)[\s]*$/)
          if match
            match[0]
          else
            ''
          end
        end
      end

      # True if the current offset is inside a string.
      #
      # @return [Boolean]
      def string?
        # @string ||= (node.type == :str or node.type == :dstr)
        @string ||= @source.string_at?(position)
      end

      # @return [Integer]
      def offset
        @offset ||= get_offset(position.line, position.column)
      end

      # @param line [Integer]
      # @param column [Integer]
      # @return [Integer]
      def get_offset line, column
        Position.line_char_to_offset(@source.code, line, column)
      end

      def signature_data
        @signature_data ||= get_signature_data_at(offset)
      end

      def get_signature_data_at index
        brackets = 0
        squares = 0
        parens = 0
        index -=1
        in_whitespace = false
        while index >= 0
          pos = Position.from_offset(@source.code, index)
          break if index > 0 and @source.comment_at?(pos)
          break if brackets > 0 or parens > 0 or squares > 0
          char = @source.code[index, 1]
          break if char.nil? # @todo Is this the right way to handle this?
          if brackets.zero? and parens.zero? and squares.zero? and [' ', "\r", "\n", "\t"].include?(char)
            in_whitespace = true
          else
            if brackets.zero? and parens.zero? and squares.zero? and in_whitespace
              unless char == '.' or @source.code[index+1..-1].strip.start_with?('.')
                old = @source.code[index+1..-1]
                nxt = @source.code[index+1..-1].lstrip
                index += (@source.code[index+1..-1].length - @source.code[index+1..-1].lstrip.length)
                break
              end
            end
            if char == ')'
              parens -=1
            elsif char == ']'
              squares -=1
            elsif char == '}'
              brackets -= 1
            elsif char == '('
              parens += 1
            elsif char == '{'
              brackets += 1
            elsif char == '['
              squares += 1
            end
            if brackets.zero? and parens.zero? and squares.zero?
              break if ['"', "'", ',', ';', '%'].include?(char)
              break if ['!', '?'].include?(char) && index < offset - 1
              break if char == '$'
              if char == '@'
                index -= 1
                if @source.code[index, 1] == '@'
                  index -= 1
                end
                break
              end
            elsif parens == 1 || brackets == 1 || squares == 1
              break
            end
            in_whitespace = false
          end
          index -= 1
        end
        index + 1
      end
    end
  end
end
