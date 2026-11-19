require "i18n/tasks"

RSpec.describe I18n do
  # Pre-filter files and ERB scriptlets that contain no translation call tokens
  # before invoking whitequark/parser, while delegating all matches to the
  # standard i18n-tasks AST scanners.
  translation_call_pattern = /
    I18n\s*\.\s*t(?:ranslate)?!? |
    \b(?:t|translate)!?\s*[('":%<] |
    \b(?:default_i18n_subject|human_attribute_name|model_name\s*\.\s*human)\b |
    i18n-tasks-use
  /x

  fast_ruby_scanner = Class.new(I18n::Tasks::Scanners::RubyAstScanner) do
    define_method(:scan_file) do |path|
      return [] unless translation_call_pattern.match?(read_file(path))

      super(path)
    end
  end

  fast_erb_scanner = Class.new(I18n::Tasks::Scanners::ErbAstScanner) do
    define_method(:scan_file) do |path|
      source = read_file(path)
      return [] unless source.include?("<%") && translation_call_pattern.match?(source)

      super(path)
    end

    define_method(:handle_code) do |buffer, code, start, stop|
      return [nil, []] unless translation_call_pattern.match?(code)

      super(buffer, code, start, stop)
    end
  end

  fast_task_class = Class.new(I18n::Tasks::BaseTask) do
    # missing_used_forest iterates every locale and calls used_tree(strict: true)
    # repeatedly without caching; memoize the immutable tree per argument tuple.
    def used_tree(key_filter: nil, strict: nil, include_raw_references: false)
      @used_tree_cache ||= {}
      cache_key = [key_filter, strict?(strict), include_raw_references]
      @used_tree_cache[cache_key] ||= super
    end

    define_method(:scanner) do |strict: nil|
      (@scanner ||= {})[strict?(strict)] ||= begin
        shared_options = search_config.dup
        shared_options.delete(:scanners)
        shared_options[:strict] = strict unless strict.nil?

        scanners = search_config[:scanners].map do |(class_name, args)|
          scanner_class = case class_name.delete_prefix("::")
                          when "I18n::Tasks::Scanners::RubyAstScanner" then fast_ruby_scanner
                          when "I18n::Tasks::Scanners::ErbAstScanner" then fast_erb_scanner
                          else ActiveSupport::Inflector.constantize(class_name)
                          end
          scanner_class.new(
            config: merge_scanner_configs(shared_options, args || {}),
            file_finder_provider: caching_file_finder_provider,
            file_reader: caching_file_reader,
          )
        end

        I18n::Tasks::Scanners::ScannerMultiplexer.new(scanners: scanners)
      end
    end
  end

  # Share a single read-only task instance across examples so locale YAML files
  # are loaded and parsed once instead of once per example.
  shared_i18n_task = fast_task_class.new
  let(:i18n) { shared_i18n_task }
  let(:missing_keys) { i18n.missing_keys }
  let(:inconsistent_interpolations) { i18n.inconsistent_interpolations }

  def details(keys)
    keys.leaves.map do |node|
      { key: node.full_key, file: node.data[:path] }
    end
  end

  it "does not have missing keys" do
    expect(missing_keys).to be_empty,
                            "Missing #{missing_keys.leaves.count} i18n keys\n #{details(missing_keys)}"
  end

  it "does not have inconsistent interpolations" do
    error_message = "#{inconsistent_interpolations.leaves.count} i18n keys have inconsistent interpolations.\n" \
                    "Run `i18n-tasks check-consistent-interpolations' to show them"
    expect(inconsistent_interpolations).to be_empty, error_message
  end
end
