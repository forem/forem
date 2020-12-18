# frozen_string_literal: true

require 'better_html'
require 'tempfile'
require 'erb_lint/utils/offset_corrector'

module ERBLint
  module Linters
    # Run selected rubocop cops on Ruby code
    class Rubocop < Linter
      include LinterRegistry

      class ConfigSchema < LinterConfig
        property :only, accepts: array_of?(String)
        property :rubocop_config, accepts: Hash, default: -> { {} }
      end

      self.config_schema = ConfigSchema

      SUFFIX_EXPR = /[[:blank:]]*\Z/
      # copied from Rails: action_view/template/handlers/erb/erubi.rb
      BLOCK_EXPR = /\s*((\s+|\))do|\{)(\s*\|[^|]*\|)?\s*\Z/

      def initialize(file_loader, config)
        super
        @only_cops = @config.only
        custom_config = config_from_hash(@config.rubocop_config)
        @rubocop_config = ::RuboCop::ConfigLoader.merge_with_default(custom_config, '')
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
        return if indicator&.children&.first == '#'

        original_source = code_node.loc.source
        trimmed_source = original_source.sub(BLOCK_EXPR, '').sub(SUFFIX_EXPR, '')
        alignment_column = code_node.loc.column
        offset = code_node.loc.begin_pos - alignment_column
        aligned_source = "#{' ' * alignment_column}#{trimmed_source}"

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
        ::RuboCop::ProcessedSource.new(
          content,
          @rubocop_config.target_ruby_version,
          filename
        )
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
          auto_correct: true,
          stdin: "",
        )
      end

      def config_from_hash(hash)
        inherit_from = hash&.delete('inherit_from')
        resolve_inheritance(hash, inherit_from)

        tempfile_from('.erblint-rubocop', hash.to_yaml) do |tempfile|
          ::RuboCop::ConfigLoader.load_file(tempfile.path)
        end
      end

      def resolve_inheritance(hash, inherit_from)
        base_configs(inherit_from)
          .reverse_each do |base_config|
          base_config.each do |k, v|
            hash[k] = hash.key?(k) ? ::RuboCop::ConfigLoader.merge(v, hash[k]) : v if v.is_a?(Hash)
          end
        end
      end

      def base_configs(inherit_from)
        regex = URI::DEFAULT_PARSER.make_regexp(%w(http https))
        configs = Array(inherit_from).compact.map do |base_name|
          if base_name =~ /\A#{regex}\z/
            ::RuboCop::ConfigLoader.load_file(::RuboCop::RemoteConfig.new(base_name, Dir.pwd))
          else
            config_from_hash(@file_loader.yaml(base_name))
          end
        end

        configs.compact
      end

      def add_offense(rubocop_offense, offense_range, correction, offset, bound_range)
        context = if rubocop_offense.corrected?
          { rubocop_correction: correction, offset: offset, bound_range: bound_range }
        end

        super(offense_range, rubocop_offense.message.strip, context)
      end
    end
  end
end
