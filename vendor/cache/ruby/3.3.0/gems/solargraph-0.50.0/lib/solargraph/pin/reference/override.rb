# frozen_string_literal: true

module Solargraph
  module Pin
    class Reference
      class Override < Reference
        # @return [Array<YARD::Tags::Tag>]
        attr_reader :tags

        # @return [Array<Symbol>]
        attr_reader :delete

        def initialize location, name, tags, delete = []
          super(location: location, name: name)
          @tags = tags
          @delete = delete
        end

        def self.method_return name, *tags, delete: []
          new(nil, name, [YARD::Tags::Tag.new('return', nil, tags)], delete)
        end

        def self.from_comment name, comment
          new(nil, name, Solargraph::Source.parse_docstring(comment).to_docstring.tags)
        end
      end
    end
  end
end
