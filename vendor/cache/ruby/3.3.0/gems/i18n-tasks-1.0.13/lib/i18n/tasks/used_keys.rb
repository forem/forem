# frozen_string_literal: true

require 'find'
require 'i18n/tasks/scanners/pattern_with_scope_scanner'
require 'i18n/tasks/scanners/ruby_ast_scanner'
require 'i18n/tasks/scanners/erb_ast_scanner'
require 'i18n/tasks/scanners/scanner_multiplexer'
require 'i18n/tasks/scanners/files/caching_file_finder_provider'
require 'i18n/tasks/scanners/files/caching_file_reader'

# Require the pattern mapper even though it's not used by i18n-tasks directly.
# This allows the user to use it in config/i18n-tasks.yml without having to require it.
# See https://github.com/glebm/i18n-tasks/issues/204.
require 'i18n/tasks/scanners/pattern_mapper'

module I18n::Tasks
  module UsedKeys # rubocop:disable Metrics/ModuleLength
    SEARCH_DEFAULTS = {
      paths: %w[app/].freeze,
      relative_exclude_method_name_paths: [],
      relative_roots: %w[app/controllers app/helpers app/mailers app/presenters app/views].freeze,
      scanners: [
        ['::I18n::Tasks::Scanners::RubyAstScanner', { only: %w[*.rb] }],
        ['::I18n::Tasks::Scanners::ErbAstScanner', { only: %w[*.erb] }],
        ['::I18n::Tasks::Scanners::PatternWithScopeScanner', { exclude: %w[*.erb *.rb] }]
      ],
      ast_matchers: [],
      strict: true
    }.freeze

    ALWAYS_EXCLUDE = %w[*.jpg *.jpeg *.png *.gif *.svg *.ico *.eot *.otf *.ttf *.woff *.woff2 *.pdf *.css *.sass *.scss
                        *.less *.yml *.json *.zip *.tar.gz *.swf *.flv *.mp3 *.wav *.flac *.webm *.mp4 *.ogg *.opus
                        *.webp *.map *.xlsx].freeze

    # Find all keys in the source and return a forest with the keys in absolute form and their occurrences.
    #
    # @param key_filter [String] only return keys matching this pattern.
    # @param strict [Boolean] if true, dynamic keys are excluded (e.g. `t("category.#{ category.key }")`)
    # @param include_raw_references [Boolean] if true, includes reference usages as they appear in the source
    # @return [Data::Tree::Siblings]
    def used_tree(key_filter: nil, strict: nil, include_raw_references: false)
      src_tree = used_in_source_tree(key_filter: key_filter, strict: strict)
      raw_refs, resolved_refs, used_refs = process_references(src_tree['used'].children)
      raw_refs.leaves { |node| node.data[:ref_type] = :reference_usage }
      resolved_refs.leaves { |node| node.data[:ref_type] = :reference_usage_resolved }
      used_refs.leaves { |node| node.data[:ref_type] = :reference_usage_key }
      src_tree.tap do |result|
        tree = result['used'].children
        tree.subtract_by_key!(raw_refs)
        tree.merge!(raw_refs) if include_raw_references
        tree.merge!(used_refs).merge!(resolved_refs)
      end
    end

    def used_in_source_tree(key_filter: nil, strict: nil)
      keys = ((@keys_used_in_source_tree ||= {})[strict?(strict)] ||=
                scanner(strict: strict).keys.freeze)
      if key_filter
        key_filter_re = compile_key_pattern(key_filter)
        keys          = keys.select { |k| k.key =~ key_filter_re }
      end
      Data::Tree::Node.new(
        key: 'used',
        data: { key_filter: key_filter },
        children: Data::Tree::Siblings.from_key_occurrences(keys)
      ).to_siblings
    end

    def scanner(strict: nil)
      (@scanner ||= {})[strict?(strict)] ||= begin
        shared_options = search_config.dup
        shared_options.delete(:scanners)
        shared_options[:strict] = strict unless strict.nil?
        log_verbose 'Scanners: '
        Scanners::ScannerMultiplexer.new(
          scanners: search_config[:scanners].map do |(class_name, args)|
            if args && args[:strict]
              fail CommandError, 'the strict option is global and cannot be applied on the scanner level'
            end

            ActiveSupport::Inflector.constantize(class_name).new(
              config: merge_scanner_configs(shared_options, args || {}),
              file_finder_provider: caching_file_finder_provider,
              file_reader: caching_file_reader
            )
          end.tap { |scanners| log_verbose { scanners.map { |s| "  #{s.class.name} #{s.config.inspect}" } * "\n" } }
        )
      end
    end

    def search_config
      @search_config ||= begin
        conf = (config[:search] || {}).deep_symbolize_keys
        if conf[:scanner]
          warn_deprecated 'search.scanner is now search.scanners, an array of [ScannerClass, options]'
          conf[:scanners] = [[conf.delete(:scanner)]]
        end
        if conf[:ignore_lines]
          warn_deprecated 'search.ignore_lines is no longer a global setting: pass it directly to the pattern scanner.'
          conf.delete(:ignore_lines)
        end
        if conf[:include]
          warn_deprecated 'search.include is now search.only'
          conf[:only] = conf.delete(:include)
        end
        merge_scanner_configs(SEARCH_DEFAULTS, conf).freeze
      end
    end

    def merge_scanner_configs(a, b)
      a.deep_merge(b).tap do |c|
        %i[scanners paths relative_exclude_method_name_paths relative_roots].each do |key|
          c[key] = a[key] if b[key].blank?
        end
        %i[exclude].each do |key|
          merged = Array(a[key]) + Array(b[key])
          c[key] = merged unless merged.empty?
        end
      end
    end

    def caching_file_finder_provider
      @caching_file_finder_provider ||= Scanners::Files::CachingFileFinderProvider.new(exclude: ALWAYS_EXCLUDE)
    end

    def caching_file_reader
      @caching_file_reader ||= Scanners::Files::CachingFileReader.new
    end

    # @return [Boolean] whether the key is potentially used in a code expression such as `t("category.#{category_key}")`
    def used_in_expr?(key)
      !!(key =~ expr_key_re)
    end

    private

    # @param strict [Boolean, nil]
    # @return [Boolean]
    def strict?(strict)
      strict.nil? ? search_config[:strict] : strict
    end

    # keys in the source that end with a ., e.g. t("category.#{ cat.i18n_key }") or t("category." + category.key)
    # @param [String] replacement for interpolated values.
    def expr_key_re(replacement: '*:')
      @expr_key_re ||= begin
        # disallow patterns with no keys
        ignore_pattern_re = /\A[.#{replacement}]*\z/
        patterns          = used_in_source_tree(strict: false).key_names.select do |k|
          k.end_with?('.') || k =~ /\#{/
        end.map do |k|
          pattern = "#{replace_key_exp(k, replacement)}#{replacement if k.end_with?('.')}"
          next if pattern =~ ignore_pattern_re

          pattern
        end.compact
        compile_key_pattern "{#{patterns * ','}}"
      end
    end

    # Replace interpolations in dynamic keys such as "category.#{category.i18n_key}".
    # @param key [String]
    # @param replacement [String]
    # @return [String]
    def replace_key_exp(key, replacement)
      scanner = StringScanner.new(key)
      braces  = []
      result  = []
      while (match_until = scanner.scan_until(/(?:#?\{|})/))
        case scanner.matched
        when '#{'
          braces << scanner.matched
          result << match_until[0..-3] if braces.length == 1
        when '}'
          prev_brace = braces.pop
          result << replacement if braces.empty? && prev_brace == '#{'
        else
          braces << '{'
        end
      end
      result << key[scanner.pos..] unless scanner.eos?
      result.join
    end
  end
end
