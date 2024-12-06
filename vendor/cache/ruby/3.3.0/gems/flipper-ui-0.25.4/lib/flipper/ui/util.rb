module Flipper
  module UI
    module Util
      # Private: 0x3000: fullwidth whitespace
      NON_WHITESPACE_REGEXP = /[^\s#{[0x3000].pack("U")}]/

      def self.blank?(str)
        str.to_s !~ NON_WHITESPACE_REGEXP
      end

      def self.present?(str)
        !blank?(str)
      end

      def self.titleize(str)
        str.to_s.split('_').map(&:capitalize).join(' ')
      end

      def self.truncate(str, length: 30)
        if str.length > length
          str[0..length]
        else
          str
        end
      end

      def self.pluralize(count, singular, plural)
        if count == 1
          "#{count} #{singular}"
        else
          "#{count} #{plural}"
        end
      end

      def self.to_sentence(array, options = {})
        default_connectors = {
          words_connector: ", ",
          two_words_connector: " and ",
          last_word_connector: ", and "
        }
        options = default_connectors.merge!(options)

        case array.length
        when 0
          ""
        when 1
          "#{array[0]}"
        when 2
          "#{array[0]}#{options[:two_words_connector]}#{array[1]}"
        else
          "#{array[0...-1].join(options[:words_connector])}#{options[:last_word_connector]}#{array[-1]}"
        end
      end
    end
  end
end
