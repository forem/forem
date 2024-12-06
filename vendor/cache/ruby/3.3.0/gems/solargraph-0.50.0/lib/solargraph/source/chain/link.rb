# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class Link
        # @return [String]
        attr_reader :word

        attr_accessor :last_context

        def initialize word = '<undefined>'
          @word = word
        end

        def undefined?
          word == '<undefined>'
        end

        def constant?
          is_a?(Chain::Constant)
        end

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [Array<Pin::Base>]
        # @return [Array<Pin::Base>]
        def resolve api_map, name_pin, locals
          []
        end

        def head?
          @head ||= false
        end

        def == other
          self.class == other.class and word == other.word
        end

        # Make a copy of this link marked as the head of a chain
        #
        # @return [self]
        def clone_head
          clone.mark_head(true)
        end

        # Make a copy of this link unmarked as the head of a chain
        #
        # @return [self]
        def clone_body
          clone.mark_head(false)
        end

        def nullable?
          false
        end

        protected

        # Mark whether this link is the head of a chain
        #
        # @param bool [Boolean]
        # @return [self]
        def mark_head bool
          @head = bool
          self
        end
      end
    end
  end
end
