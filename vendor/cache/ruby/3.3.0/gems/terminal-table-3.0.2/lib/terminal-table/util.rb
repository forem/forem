module Terminal
  class Table
    module Util
      # removes all ANSI escape sequences (e.g. color)
      def ansi_escape(line)
        line.to_s.gsub(/\x1b(\[|\(|\))[;?0-9]*[0-9A-Za-z]/, '').
          gsub(/\x1b(\[|\(|\))[;?0-9]*[0-9A-Za-z]/, '').
          gsub(/(\x03|\x1a)/, '')
      end
      module_function :ansi_escape
    end
  end
end
