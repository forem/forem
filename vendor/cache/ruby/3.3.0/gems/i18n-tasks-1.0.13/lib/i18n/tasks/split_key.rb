# frozen_string_literal: true

module I18n
  module Tasks
    module SplitKey
      module_function

      # split a key by dots (.)
      # dots inside braces or parenthesis are not split on
      #
      # split_key 'a.b'      # => ['a', 'b']
      # split_key 'a.#{b.c}' # => ['a', '#{b.c}']
      # split_key 'a.b.c', 2 # => ['a', 'b.c']
      def split_key(key, max = Float::INFINITY)
        parts = []
        pos   = 0
        return [key] if max == 1

        key_parts(key) do |part|
          parts << part
          pos += part.length + 1
          if parts.length + 1 >= max
            parts << key[pos..] unless pos == key.length
            break
          end
        end
        parts
      end

      def last_key_part(key)
        last = nil
        key_parts(key) { |part| last = part }
        last
      end

      # yield each key part
      # dots inside braces or parenthesis are not split on
      def key_parts(key, &block)
        return enum_for(:key_parts, key) unless block

        nesting = PARENS
        counts  = PARENS_ZEROS # dup'd later if key contains parenthesis
        delim   = '.'
        from    = to = 0
        key.each_char do |char|
          if char == delim && PARENS_ZEROS == counts
            block.yield key[from...to]
            from = to = (to + 1)
          else
            nest_i, nest_inc = nesting[char]
            if nest_i
              counts = counts.dup if counts.frozen?
              counts[nest_i] += nest_inc
            end
            to += 1
          end
        end
        block.yield(key[from...to]) if from < to && to <= key.length
        true
      end

      PARENS = %w({} [] ()).each_with_object({}) do |s, h|
        i              = h.size / 2
        h[s[0].freeze] = [i, 1].freeze
        h[s[1].freeze] = [i, -1].freeze
      end.freeze
      PARENS_ZEROS = Array.new(PARENS.size, 0).freeze
      private_constant :PARENS
      private_constant :PARENS_ZEROS
    end
  end
end
