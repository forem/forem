# frozen_string_literal: true
module YARD
  module Tags
    class OverloadTag < Tag
      attr_reader :signature, :parameters, :docstring

      def initialize(tag_name, text)
        super(tag_name, nil)
        parse_tag(text)
        parse_signature
      end

      def tag(name) docstring.tag(name) end
      def tags(name = nil) docstring.tags(name) end
      def has_tag?(name) docstring.has_tag?(name) end

      def object=(value)
        super(value)
        docstring.object = value
        docstring.tags.each {|tag| tag.object = value }
      end

      def name(prefix = false)
        return @name unless prefix
        object.scope == :class ? @name.to_s : "#{object.send(:sep)}#{@name}"
      end

      def method_missing(*args, &block)
        object.send(*args, &block)
      end

      def type
        object.type
      end

      def is_a?(other)
        object.is_a?(other) || self.class >= other.class || false
      end
      alias kind_of? is_a?

      private

      def parse_tag(text)
        @signature, text = *text.split(/\r?\n/, 2)
        @signature.strip!
        text ||= String.new("")
        numspaces = text[/\A(\s*)/, 1].length
        text.gsub!(/^[ \t]{#{numspaces}}/, '')
        text.strip!
        @docstring = Docstring.new(text, nil)
      end

      def parse_signature
        if signature =~ /^(?:def\s)?\s*(#{CodeObjects::METHODMATCH})(?:(?:\s+|\s*\()(.*)(?:\)\s*$)?)?/m
          meth = $1
          args = $2
          meth.gsub!(/\s+/, '')
          # FIXME: refactor this code to not make use of the Handlers::Base class (tokval_list should be moved)
          toks = YARD::Parser::Ruby::Legacy::TokenList.new(args)
          args = YARD::Handlers::Ruby::Legacy::Base.new(nil, nil).send(:tokval_list, toks, :all)
          args = args.map do |a|
            k, v = *a.split(/:|=/, 2)
            [k.strip.to_s + (a[k.size, 1] == ':' ? ':' : ''), (v ? v.strip : nil)]
          end if args
          @name = meth.to_sym
          @parameters = args
        end
      end
    end
  end
end
