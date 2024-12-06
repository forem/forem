# frozen_string_literal: true

require "better_html"
require "tempfile"
require "erb_lint/utils/offset_corrector"

module ERBLint
  module Linters
    # Run selected rubocop cops on Ruby code
    class Rubocop < Linter
      include LinterRegistry

      class ConfigSchema < LinterConfig
        property :only, accepts: array_of?(String)
        property :rubocop_config, accepts: Hash, default: -> { {} }
        property :config_file_path, accepts: String
      end

      self.config_schema = ConfigSchema

      SUFFIX_EXPR = /[[:blank:]]*\Z/
      # copied from Rails: action_view/template/handlers/erb/erubi.rb
      BLOCK_EXPR = /\s*((\s+|\))do|\{)(\s*\|[^|]*\|)?\s*\Z/

      def initialize(file_loader, config)
        super
        @only_cops = @config.only
        custom_config = config_from_path(@config.config_file_path) if @config.config_file_path
        custom_config ||= config_from_hash(@config.rubocop_config)
        @rubocop_config = ::RuboCop::ConfigLoader.merge_with_default(custom_config, "")
      end

      def run(processed_source)
        descendant_nodes(processed_source).each do |erb_node|
          inspect_content(processed_source, erb_node)
        end
      end

      if ::RuboCop::Version::STRING.to_f >= 0.87
        def autocorrect(_processed_source, offense)
          return unless offense.context

          rubocop_correction = offense.context[:rubocop_correction]
          return unless rubocop_correction

          lambda do |corrector|
            corrector.import!(rubocop_correction, offset: offense.context[:offset])
          end
        end
      else
        def autocorrect(processed_source, offense)
          return unless offense.context

          lambda do |corrector|
            passthrough = Utils::OffsetCorrector.new(
              processed_source,
              corrector,
              offense.context[:offset],
              offense.context[:bound_range],
            )
            offense.context[:rubocop_correction].call(passthrough)
          end
        end
      end

      private

      def descendant_nodes(processed_source)
        processed_source.ast.descendants(:erb)
      end

      def inspect_content(processed_source, erb_node)
        indicator, _, code_node, = *erb_node
        return if indicator&.children&.first == "#"

        original_source = code_node.loc.source
        trimmed_source = original_source.sub(BLOCK_EXPR, "").sub(SUFFIX_EXPR, "")
        alignment_column = code_node.loc.column
        offset = code_node.loc.begin_pos - alignment_column
        aligned_source = "#{" " * alignment_column}#{trimmed_source}"

        source = rubocop_processed_source(aligned_source, processed_source.filename)
        return unless source.valid_syntax?

        activate_team(processed_source, source, offset, code_node, build_team)
      end

      if ::RuboCop::Version::STRING.to_f >= 0.87
        def activate_team(processed_source, source, offset, code_node, team)
          report = team.investigate(source)
          report.offenses.each do |rubocop_offense|
            next if rubocop_offense.disabled?

            correction = rubocop_offense.corrector if rubocop_offense.corrected?

            offense_range = processed_source
              .to_source_range(rubocop_offense.location)
              .offset(offset)

            add_offense(rubocop_offense, offense_range, correction, offset, code_node.loc.range)
          end
        end
      else
        def activate_team(processed_source, source, offset, code_node, team)
          team.inspect_file(source)
          team.cops.each do |cop|
            correction_offset = 0
            cop.offenses.reject(&:disabled?).each do |rubocop_offense|
              if rubocop_offense.corrected?
                correction = cop.corrections[correction_offset]
                correction_offset += 1
              end

              offense_range = processed_source
                .to_source_range(rubocop_offense.location)
                .offset(offset)

              add_offense(rubocop_offense, offense_range, correction, offset, code_node.loc.range)
            end
          end
        end
      end

      def tempfile_from(filename, content)
        Tempfile.create(File.basename(filename), Dir.pwd) do |tempfile|
          tempfile.write(content)
          tempfile.rewind

          yield(tempfile)
        end
      end

      def rubocop_processed_source(content, filename)
        source = ::RuboCop::ProcessedSource.new(
          content,
          @rubocop_config.target_ruby_version,
          filename
        )
        if ::RuboCop::Version::STRING.to_f >= 1.38
          registry = RuboCop::Cop::Registry.global
          source.registry = registry
          source.config = @rubocop_config
        end
        source
      end

      def cop_classes
        if @only_cops.present?
          selected_cops = ::RuboCop::Cop::Cop.all.select { |cop| cop.match?(@only_cops) }
          ::RuboCop::Cop::Registry.new(selected_cops)
        else
          ::RuboCop::Cop::Registry.new(::RuboCop::Cop::Cop.all)
        end
      end

      def build_team
        ::RuboCop::Cop::Team.new(
          cop_classes,
          @rubocop_config,
          extra_details: true,
          display_cop_names: true,
          autocorrect: true,
          auto_correct: true,
          stdin: "",
        )
      end

      def config_from_hash(hash)
        tempfile_from(".erblint-rubocop", hash.to_yaml) do |tempfile|
          config_from_path(tempfile.path)
        end
      end

      def config_from_path(path)
        ::RuboCop::ConfigLoader.load_file(path)
      end

      def add_offense(rubocop_offense, offense_range, correction, offset, bound_range)
        context = if rubocop_offense.corrected?
          { rubocop_correction: correction, offset: offset, bound_range: bound_range }
        end

        super(offense_range, rubocop_offense.message.strip, context, rubocop_offense.severity.name)
      end
    end
  end
end
