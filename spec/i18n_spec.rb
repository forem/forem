require "i18n/tasks"
require "prism"
require "tmpdir"

# Speeds up the read-only i18n-tasks audit by pre-filtering files and ERB tags
# without translation calls, parsing non-controller/mailer Ruby files via masked
# Prism slices instead of running whitequark/parser over entire unrelated files,
# and memoizing the immutable used_tree across locales.
module I18nSpecScanners
  CALL_NAMES = %i[t t! translate translate!].freeze
  MODIFIER_NODES = [Prism::IfNode, Prism::UnlessNode, Prism::WhileNode, Prism::UntilNode].freeze
  AST_MATCHER_HINT = /\b(?:default_i18n_subject|human_attribute_name|model_name\s*\.\s*human)\b/
  TRANSLATION_HINT = /
    I18n\s*\.\s*t(?:ranslate)?!? |
    \b(?:t|translate)!?(?:\s|[('":%<]) |
    \b(?:default_i18n_subject|human_attribute_name|model_name\s*\.\s*human)\b |
    i18n-tasks-use
  /x

  class RubyAstScanner < I18n::Tasks::Scanners::RubyAstScanner
    protected

    def scan_file(path)
      source = read_file(path)
      return [] unless TRANSLATION_HINT.match?(source)
      if source.include?("i18n-tasks-use") || AST_MATCHER_HINT.match?(source) || keys_relative_to_calling_method?(path)
        return super
      end

      nodes, modifier_reordered = extract_i18n_nodes(source)
      return [] if nodes.empty?
      return super if modifier_reordered

      ast = @parser.tap(&:reset).parse(make_buffer(path, mask_non_i18n_source(source, nodes)))
      return super if ast.nil?

      restore_occurrence_lines(ast_to_occurences(ast), source)
    rescue Parser::SyntaxError
      super
    end

    private

    def extract_i18n_nodes(source)
      nodes = []
      modifier_ranges = []
      stack = [Prism.parse(source).value]
      while (node = stack.pop)
        if node.is_a?(Prism::CallNode) && CALL_NAMES.include?(node.name) && i18n_receiver?(node.receiver)
          nodes << node
          next
        end
        collect_modifier_range(node, modifier_ranges)
        stack.concat(node.compact_child_nodes.reverse)
      end
      nodes.sort_by! { |call_node| call_node.location.start_offset }
      [nodes, modifier_reordered?(nodes, modifier_ranges)]
    end

    def collect_modifier_range(node, modifier_ranges)
      return unless MODIFIER_NODES.any? { |klass| node.is_a?(klass) }
      return unless node.statements && node.predicate.location.start_offset > node.statements.location.start_offset

      modifier_ranges << [node.statements.location, node.predicate.location]
    end

    def modifier_reordered?(nodes, modifier_ranges)
      return false if modifier_ranges.empty? || nodes.size < 2

      modifier_ranges.any? do |stmt_loc, pred_loc|
        node_in_location?(nodes, stmt_loc) && node_in_location?(nodes, pred_loc)
      end
    end

    def node_in_location?(nodes, location)
      nodes.any? do |call_node|
        call_node.location.start_offset >= location.start_offset &&
          call_node.location.end_offset <= location.end_offset
      end
    end

    def mask_non_i18n_source(source, nodes)
      masked = +""
      cursor = 0
      nodes.each_with_index do |node, index|
        location = node.location
        gap = source.byteslice(cursor, location.start_offset - cursor).gsub(/[^\r\n]/, " ")
        gap[0] = ";" if index.positive? && gap.index("\n").nil? && !gap.empty?
        masked << gap << location.slice
        cursor = location.end_offset
      end
      masked
    end

    def restore_occurrence_lines(occurrences, source)
      return occurrences if occurrences.empty?

      lines = source.split(/\r?\n/, -1)
      occurrences.map do |key, occ|
        [
          key,
          I18n::Tasks::Scanners::Results::Occurrence.new(
            path: occ.path,
            pos: occ.pos,
            line_num: occ.line_num,
            line_pos: occ.line_pos,
            line: lines[occ.line_num - 1],
            raw_key: occ.raw_key,
            default_arg: occ.default_arg,
          ),
        ]
      end
    end

    def i18n_receiver?(receiver)
      return true if receiver.nil?
      return receiver.name == :I18n if receiver.is_a?(Prism::ConstantReadNode)

      receiver.is_a?(Prism::ConstantPathNode) && receiver.parent.nil? && receiver.name == :I18n
    end
  end

  class ErbAstScanner < I18n::Tasks::Scanners::ErbAstScanner
    def initialize(**args)
      super
      @skip_erb_tag_pruning = false
    end

    protected

    def scan_file(path)
      source = read_file(path)
      return [] unless source.include?("<%") && TRANSLATION_HINT.match?(source)

      @skip_erb_tag_pruning = source.include?("i18n-tasks-use")
      super
    ensure
      @skip_erb_tag_pruning = false
    end

    private

    def handle_code(buffer, code, start, stop)
      return super if @skip_erb_tag_pruning || TRANSLATION_HINT.match?(code)

      [nil, []]
    end
  end

  class Task < I18n::Tasks::BaseTask
    # missing_used_forest iterates every locale and calls used_tree(strict: true)
    # repeatedly without caching; memoize the immutable tree per argument tuple.
    def used_tree(key_filter: nil, strict: nil, include_raw_references: false)
      @used_tree_cache ||= {}
      cache_key = [key_filter, strict?(strict), include_raw_references]
      @used_tree_cache[cache_key] ||= super
    end

    def scanner(strict: nil)
      (@scanner ||= {})[strict?(strict)] ||= begin
        shared_options = search_config.dup
        shared_options.delete(:scanners)
        shared_options[:strict] = strict unless strict.nil?

        scanners = search_config[:scanners].map do |(class_name, args)|
          scanner_class = case class_name.delete_prefix("::")
                          when "I18n::Tasks::Scanners::RubyAstScanner" then RubyAstScanner
                          when "I18n::Tasks::Scanners::ErbAstScanner" then ErbAstScanner
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

  def self.task
    @task ||= Task.new
  end
end

RSpec.describe I18n do
  # Share a single read-only task instance across examples so locale YAML files
  # are loaded and parsed once instead of once per example.
  let(:i18n) { I18nSpecScanners.task }
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

  describe "scanner parity" do
    def key_snapshots(scanner)
      scanner.keys.map do |key_occurrences|
        [
          key_occurrences.key,
          key_occurrences.occurrences.map do |occ|
            [occ.path, occ.pos, occ.line_num, occ.line_pos, occ.line, occ.raw_key, occ.default_arg]
          end,
        ]
      end
    end

    it "matches default scanners on line_pos, UTF-8 CRLF fixtures, modifier conditions, and AST matchers" do
      Dir.mktmpdir do |dir|
        File.binwrite(
          File.join(dir, "utf8_crlf.rb"),
          "# café — naïve\r\n" \
          "label = \"héllo\" + I18n.t(\"first.key\") + I18n.t(\"second.key\")\r\n" \
          "I18n.t(\"third.key\", default: \"Défault\")\r\n",
        )
        File.write(
          File.join(dir, "modifier.rb"),
          "I18n.t(\"audit_ui.label\") if I18n.t(\"audit_ui\")\n" \
          "I18n.t(\"audit_ui.unless_label\") unless I18n.t(\"audit_ui.unless_cond\")\n" \
          "I18n.t(\"sibling.one\"); I18n.t(\"sibling.two\")\n",
        )
        File.write(
          File.join(dir, "compact_and_matchers.rb"),
          "I18n.t'compact.key'\n" \
          "User.human_attribute_name(:email)\n",
        )

        config = { paths: [dir] }
        custom = key_snapshots(I18nSpecScanners::RubyAstScanner.new(config: config))
        default = key_snapshots(I18n::Tasks::Scanners::RubyAstScanner.new(config: config))
        expect(custom).to eq(default)
      end
    end
  end
end
