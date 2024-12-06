# frozen_string_literal: true

require 'i18n/tasks/data/tree/node'
require 'i18n/tasks/data/router/pattern_router'
require 'i18n/tasks/data/router/conservative_router'
require 'i18n/tasks/data/file_formats'
require 'i18n/tasks/key_pattern_matching'

module I18n::Tasks
  module Data
    class FileSystemBase # rubocop:disable Metrics/ClassLength
      include ::I18n::Tasks::Data::FileFormats
      include ::I18n::Tasks::Logging

      attr_accessor :locales
      attr_reader :config, :base_locale
      attr_writer :router

      DEFAULTS = {
        read: ['config/locales/%{locale}.yml'],
        write: ['config/locales/%{locale}.yml']
      }.freeze

      def initialize(config = {})
        self.config = config.except(:base_locale, :locales)
        self.config[:sort] = !config[:keep_order]
        @base_locale = config[:base_locale]
        locales = config[:locales].presence
        @locales = LocaleList.normalize_locale_list(locales || available_locales, base_locale, true)
        if locales.present?
          log_verbose "locales read from config #{@locales * ', '}"
        else
          log_verbose "locales inferred from data: #{@locales * ', '}"
        end
      end

      # @param [String, Symbol] locale
      # @return [::I18n::Tasks::Data::Siblings]
      def get(locale)
        locale = locale.to_s
        @trees ||= {}
        @trees[locale] ||= read_locale(locale)
      end

      alias [] get

      # @param [String, Symbol] locale
      # @return [::I18n::Tasks::Data::Siblings]
      def external(locale)
        locale = locale.to_s
        @external ||= {}
        @external[locale] ||= read_locale(locale, paths: config[:external])
      end

      # set locale tree
      # @param [String, Symbol] locale
      # @param [::I18n::Tasks::Data::Siblings] tree
      def set(locale, tree)
        locale = locale.to_s
        @trees&.delete(locale)
        paths_before = Set.new(get(locale)[locale].leaves.map { |node| node.data[:path] })
        paths_after = Set.new([])
        router.route locale, tree do |path, tree_slice|
          paths_after << path
          write_tree path, tree_slice, config[:sort]
        end
        (paths_before - paths_after).each do |path|
          FileUtils.remove_file(path) if File.exist?(path)
        end
        @trees&.delete(locale)
        @available_locales = nil
      end

      alias []= set

      # @param [String] locale
      # @return [Array<String>] paths to files that are not normalized
      def non_normalized_paths(locale)
        router.route(locale, get(locale))
              .reject { |path, tree_slice| normalized?(path, tree_slice) }
              .map(&:first)
      end

      def write(forest)
        forest.each { |root| set(root.key, root.to_siblings) }
      end

      def merge!(forest)
        forest.inject(Tree::Siblings.new) do |result, root|
          locale = root.key
          merged = get(locale).merge(root)
          set locale, merged
          result.merge! merged
        end
      end

      def remove_by_key!(forest)
        forest.inject(Tree::Siblings.new) do |removed, root|
          locale = root.key
          locale_data = get(locale)
          subtracted = locale_data.subtract_by_key(forest)
          set locale, subtracted
          removed.merge! locale_data.subtract_by_key(subtracted)
        end
      end

      # @return self
      def reload
        @trees             = nil
        @available_locales = nil
        self
      end

      # Get available locales from the list of file names to read
      def available_locales
        @available_locales ||= begin
          locales = Set.new
          Array(config[:read]).map do |pattern|
            [pattern, Dir.glob(format(pattern, locale: '*'))] if pattern.include?('%{locale}')
          end.compact.each do |pattern, paths|
            p  = pattern.gsub('\\', '\\\\').gsub('/', '\/').gsub('.', '\.')
            p  = p.gsub(/(\*+)/) { Regexp.last_match(1) == '**' ? '.*' : '[^/]*?' }.gsub('%{locale}', '([^/.]+)')
            re = /\A#{p}\z/
            paths.each do |path|
              locales << Regexp.last_match(1) if re =~ path
            end
          end
          locales
        end
      end

      def t(key, locale)
        tree = self[locale.to_s]
        return unless tree

        tree[locale][key].try(:value_or_children_hash)
      end

      def config=(config)
        @config = DEFAULTS.deep_merge((config || {}).compact)
        reload
      end

      def with_router(router)
        router_was  = self.router
        self.router = router
        yield
      ensure
        self.router = router_was
      end

      ROUTER_NAME_ALIASES = {
        'conservative_router' => 'I18n::Tasks::Data::Router::ConservativeRouter',
        'pattern_router' => 'I18n::Tasks::Data::Router::PatternRouter'
      }.freeze
      def router
        @router ||= begin
          name = @config[:router].presence || 'conservative_router'
          name = ROUTER_NAME_ALIASES[name] || name
          router_class = ActiveSupport::Inflector.constantize(name)
          router_class.new(self, @config.merge(base_locale: base_locale, locales: locales))
        end
      end

      protected

      def read_locale(locale, paths: config[:read])
        Array(paths).flat_map do |path|
          Dir.glob format(path, locale: locale)
        end.map do |path|
          [path.freeze, load_file(path) || {}]
        end.map do |path, data|
          filter_nil_keys! path, data
          Data::Tree::Siblings.from_nested_hash(data).tap do |s|
            s.leaves { |x| x.data.update(path: path, locale: locale) }
          end
        end.reduce(Tree::Siblings[locale => {}], :merge!)
      end

      def filter_nil_keys!(path, data, suffix = [])
        data.each do |key, value|
          if key.nil?
            data.delete(key)
            log_warn <<~TEXT
              Skipping a nil key found in #{path.inspect}:
                key: #{suffix.join('.')}.`nil`
                value: #{value.inspect}
              Nil keys are not supported by i18n.
              The following unquoted YAML keys result in a nil key:
                #{%w[null Null NULL ~].join(', ')}
              See http://yaml.org/type/null.html
            TEXT
          elsif value.is_a?(Hash)
            filter_nil_keys! path, value, suffix + [key]
          end
        end
      end
    end
  end
end
