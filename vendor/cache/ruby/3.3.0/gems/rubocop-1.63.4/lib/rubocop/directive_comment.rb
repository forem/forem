# frozen_string_literal: true

module RuboCop
  # This class wraps the `Parser::Source::Comment` object that represents a
  # special `rubocop:disable` and `rubocop:enable` comment and exposes what
  # cops it contains.
  class DirectiveComment
    # @api private
    LINT_DEPARTMENT = 'Lint'
    # @api private
    LINT_REDUNDANT_DIRECTIVE_COP = "#{LINT_DEPARTMENT}/RedundantCopDisableDirective"
    # @api private
    LINT_SYNTAX_COP = "#{LINT_DEPARTMENT}/Syntax"
    # @api private
    COP_NAME_PATTERN = '([A-Z]\w+/)*(?:[A-Z]\w+)'
    # @api private
    COP_NAMES_PATTERN = "(?:#{COP_NAME_PATTERN} , )*#{COP_NAME_PATTERN}"
    # @api private
    COPS_PATTERN = "(all|#{COP_NAMES_PATTERN})"
    # @api private
    DIRECTIVE_COMMENT_REGEXP = Regexp.new(
      "# rubocop : ((?:disable|enable|todo))\\b #{COPS_PATTERN}"
        .gsub(' ', '\s*')
    )

    def self.before_comment(line)
      line.split(DIRECTIVE_COMMENT_REGEXP).first
    end

    attr_reader :comment, :cop_registry, :mode, :cops

    def initialize(comment, cop_registry = Cop::Registry.global)
      @comment = comment
      @cop_registry = cop_registry
      @mode, @cops = match_captures
    end

    # Checks if this directive relates to single line
    def single_line?
      !comment.text.start_with?(DIRECTIVE_COMMENT_REGEXP)
    end

    # Checks if this directive contains all the given cop names
    def match?(cop_names)
      parsed_cop_names.uniq.sort == cop_names.uniq.sort
    end

    def range
      match = comment.text.match(DIRECTIVE_COMMENT_REGEXP)
      begin_pos = comment.source_range.begin_pos
      Parser::Source::Range.new(
        comment.source_range.source_buffer, begin_pos + match.begin(0), begin_pos + match.end(0)
      )
    end

    # Returns match captures to directive comment pattern
    def match_captures
      @match_captures ||= comment.text.match(DIRECTIVE_COMMENT_REGEXP)&.captures
    end

    # Checks if this directive disables cops
    def disabled?
      %w[disable todo].include?(mode)
    end

    # Checks if this directive enables cops
    def enabled?
      mode == 'enable'
    end

    # Checks if this directive enables all cops
    def enabled_all?
      !disabled? && all_cops?
    end

    # Checks if this directive disables all cops
    def disabled_all?
      disabled? && all_cops?
    end

    # Checks if all cops specified in this directive
    def all_cops?
      cops == 'all'
    end

    # Returns array of specified in this directive cop names
    def cop_names
      @cop_names ||= all_cops? ? all_cop_names : parsed_cop_names
    end

    # Returns array of specified in this directive department names
    # when all department disabled
    def department_names
      splitted_cops_string.select { |cop| department?(cop) }
    end

    # Checks if directive departments include cop
    def in_directive_department?(cop)
      department_names.any? { |department| cop.start_with?(department) }
    end

    # Checks if cop department has already used in directive comment
    def overridden_by_department?(cop)
      in_directive_department?(cop) && splitted_cops_string.include?(cop)
    end

    def directive_count
      splitted_cops_string.count
    end

    # Returns line number for directive
    def line_number
      comment.source_range.line
    end

    private

    def splitted_cops_string
      (cops || '').split(/,\s*/)
    end

    def parsed_cop_names
      cops = splitted_cops_string.map do |name|
        department?(name) ? cop_names_for_department(name) : name
      end.flatten
      cops - [LINT_SYNTAX_COP]
    end

    def department?(name)
      cop_registry.department?(name)
    end

    def all_cop_names
      exclude_lint_department_cops(cop_registry.names)
    end

    def cop_names_for_department(department)
      names = cop_registry.names_for_department(department)
      department == LINT_DEPARTMENT ? exclude_lint_department_cops(names) : names
    end

    def exclude_lint_department_cops(cops)
      cops - [LINT_REDUNDANT_DIRECTIVE_COP, LINT_SYNTAX_COP]
    end
  end
end
