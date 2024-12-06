# frozen_string_literal: true

module I18n::Tasks
  module Translators
    class BaseTranslator
      include ::I18n::Tasks::Logging
      # @param [I18n::Tasks::BaseTask] i18n_tasks
      def initialize(i18n_tasks)
        @i18n_tasks = i18n_tasks
      end

      # @param [I18n::Tasks::Tree::Siblings] forest to translate to the locales of its root nodes
      # @param [String] from locale
      # @return [I18n::Tasks::Tree::Siblings] translated forest
      def translate_forest(forest, from)
        forest.inject @i18n_tasks.empty_forest do |result, root|
          translated = translate_pairs(root.key_values(root: true), to: root.key, from: from)
          result.merge! Data::Tree::Siblings.from_flat_pairs(translated)
        end
      end

      protected

      # @param [Array<[String, Object]>] list of key-value pairs
      # @return [Array<[String, Object]>] translated list
      def translate_pairs(list, opts)
        return [] if list.empty?

        opts = opts.dup
        key_pos = list.each_with_index.inject({}) { |idx, ((k, _v), i)| idx.update(k => i) }
        # copy reference keys as is, instead of translating
        reference_key_vals = list.select { |_k, v| v.is_a? Symbol } || []
        list -= reference_key_vals
        result = list.group_by { |k_v| @i18n_tasks.html_key? k_v[0], opts[:from] }.map do |is_html, list_slice|
          fetch_translations(list_slice, opts.merge(is_html ? options_for_html : options_for_plain))
        end.reduce(:+) || []
        result.concat(reference_key_vals)
        result.sort! { |a, b| key_pos[a[0]] <=> key_pos[b[0]] }
        result
      end

      # @param [Array<[String, Object]>] list of key-value pairs
      # @return [Array<[String, Object]>] translated list
      def fetch_translations(list, opts)
        options = options_for_translate_values(**opts)
        from_values(list, translate_values(to_values(list, options), **options), options).tap do |result|
          fail CommandError, no_results_error_message if result.blank?
        end
      end

      # @param [Array<[String, Object]>] list of key-value pairs
      # @return [Array<String>] values for translation extracted from list
      def to_values(list, opts)
        list.map { |l| dump_value(l[1], opts) }.flatten.compact
      end

      # @param [Array<[String, Object]>] list
      # @param [Array<String>] translated_values
      # @return [Array<[String, Object]>] translated key-value pairs
      def from_values(list, translated_values, opts)
        keys = list.map(&:first)
        untranslated_values = list.map(&:last)
        keys.zip parse_value(untranslated_values, translated_values.to_enum, opts)
      end

      # Prepare value for translation.
      # @return [String, Array<String, nil>, nil] value for Google Translate or nil for non-string values
      def dump_value(value, opts)
        case value
        when Array
          # dump recursively
          value.map { |v| dump_value(v, opts) }
        when String
          value = CGI.escapeHTML(value) if opts[:html_escape]
          replace_interpolations value unless value.empty?
        end
      end

      # Parse translated value from the each_translated enumerator
      # @param [Object] untranslated
      # @param [Enumerator] each_translated
      # @return [Object] final translated value
      def parse_value(untranslated, each_translated, opts)
        case untranslated
        when Array
          # implode array
          untranslated.map { |from| parse_value(from, each_translated, opts) }
        when String
          if untranslated.empty?
            untranslated
          else
            value = each_translated.next
            value = CGI.unescapeHTML(value) if opts[:html_escape]
            restore_interpolations(untranslated, value)
          end
        else
          untranslated
        end
      end

      INTERPOLATION_KEY_RE = /%\{[^}]+}/.freeze
      UNTRANSLATABLE_STRING = 'X__'

      # @param [String] value
      # @return [String] 'hello, %{name}' => 'hello, <round-trippable string>'
      def replace_interpolations(value)
        i = -1
        value.gsub INTERPOLATION_KEY_RE do
          i += 1
          "#{UNTRANSLATABLE_STRING}#{i}"
        end
      end

      # @param [String] untranslated
      # @param [String] translated
      # @return [String] 'hello, <round-trippable string>' => 'hello, %{name}'
      def restore_interpolations(untranslated, translated)
        return translated if untranslated !~ INTERPOLATION_KEY_RE

        values = untranslated.scan(INTERPOLATION_KEY_RE)
        translated.gsub(/#{Regexp.escape(UNTRANSLATABLE_STRING)}\d+/i) do |m|
          values[m[UNTRANSLATABLE_STRING.length..].to_i]
        end
      rescue StandardError => e
        raise_interpolation_error(untranslated, translated, e)
      end

      def raise_interpolation_error(untranslated, translated, e)
        fail CommandError.new(e, <<~TEXT.strip)
          Error when restoring interpolations:
            original: "#{untranslated}"
            response: "#{translated}"
            error: #{e.message} (#{e.class.name})
        TEXT
      end

      # @param [Array<String>] list
      # @param [Hash] options
      # @return [Array<String>]
      # @abstract
      def translate_values(list, **options); end

      # @param [Hash] options
      # @return [Hash]
      # @abstract
      def options_for_translate_values(options); end

      # @return [Hash]
      # @abstract
      def options_for_html; end

      # @return [Hash]
      # @abstract
      def options_for_plain; end

      # @return [String]
      # @abstract
      def no_results_error_message; end
    end
  end
end
