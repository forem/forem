# frozen_string_literal: true

gem "ruby-next-parser", ">= 2.8.0.3"
gem "unparser", ">= 0.4.7"

require "set"

require "ruby-next"

module RubyNext
  # Language module contains tools to transpile newer Ruby syntax
  # into an older one.
  #
  # It works the following way:
  #   - Takes a Ruby source code as input
  #   - Generates the AST using the edge parser (via the `parser` gem)
  #   - Pass this AST through the list of processors (one feature = one processor)
  #   - Each processor may modify the AST
  #   - Generates a transpiled source code from the transformed AST (via the `unparser` gem)
  module Language
    using RubyNext

    require "ruby-next/language/parser"
    require "ruby-next/language/unparser"

    RewriterNotFoundError = Class.new(StandardError)

    class TransformContext
      attr_reader :versions, :use_ruby_next

      def initialize
        # Minimum supported RubyNext version
        @min_version = MIN_SUPPORTED_VERSION
        @dirty = false
        @versions = Set.new
        @use_ruby_next = false
      end

      # Called by rewriter when it performs transfomrations
      def track!(rewriter)
        @dirty = true
        versions << rewriter.class::MIN_SUPPORTED_VERSION
      end

      def use_ruby_next!
        @use_ruby_next = true
      end

      alias use_ruby_next? use_ruby_next

      def dirty?
        @dirty == true
      end

      def min_version
        versions.min
      end

      def sorted_versions
        versions.to_a.sort
      end
    end

    class << self
      attr_accessor :rewriters
      attr_reader :watch_dirs

      attr_accessor :strategy

      MODES = %i[rewrite ast].freeze

      attr_reader :mode

      def mode=(val)
        raise ArgumentError, "Unknown mode: #{val}. Available: #{MODES.join(",")}" unless MODES.include?(val)
        @mode = val
      end

      def rewrite?
        mode == :rewrite?
      end

      def ast?
        mode == :ast
      end

      def runtime!
        require "ruby-next/language/rewriters/runtime"

        @runtime = true
      end

      def runtime?
        @runtime
      end

      def transform(source, rewriters: self.rewriters, using: RubyNext::Core.refine?, context: TransformContext.new)
        retried = 0
        new_source = nil
        begin
          new_source =
            if mode == :rewrite
              rewrite(source, rewriters: rewriters, using: using, context: context)
            else
              regenerate(source, rewriters: rewriters, using: using, context: context)
            end
        rescue Unparser::UnknownNodeError => err
          RubyNext.warn "Ruby Next fallbacks to \"rewrite\" transpiling mode since the version of Unparser you use doesn't support some syntax yet: #{err.message}.\n" \
            "Try upgrading the Unparser or set transpiling mode to \"rewrite\" in case you use some edge or experimental syntax."
          self.mode = :rewrite
          retried += 1
          retry unless retried > 1
          raise
        end

        return new_source unless RubyNext::Core.refine?
        return new_source unless using && context.use_ruby_next?

        Core.inject! new_source.dup
      end

      def transformable?(path)
        watch_dirs.any? { |dir| path.start_with?(dir) }
      end

      # Rewriters required for the current version
      def current_rewriters
        @current_rewriters ||= rewriters.select(&:unsupported_syntax?)
      end

      # This method guarantees that rewriters will be returned in order they defined in Language module
      def select_rewriters(*names)
        rewriters_delta = names - rewriters.map { |rewriter| rewriter::NAME }
        if rewriters_delta.any?
          raise RewriterNotFoundError, "Rewriters not found: #{rewriters_delta.join(",")}"
        end

        rewriters.select { |rewriter| names.include?(rewriter::NAME) }
      end

      private

      def regenerate(source, rewriters: ::Kernel.raise(::ArgumentError, "missing keyword: rewriters"), using: ::Kernel.raise(::ArgumentError, "missing keyword: using"), context: ::Kernel.raise(::ArgumentError, "missing keyword: context"))
        parse_with_comments(source).then do |(ast, comments)|
          rewriters.inject(ast) do |tree, rewriter|
            rewriter.new(context).process(tree)
          end.then do |new_ast|
            next source unless context.dirty?

            Unparser.unparse(new_ast, comments)
          end
        end
      end

      def rewrite(source, rewriters: ::Kernel.raise(::ArgumentError, "missing keyword: rewriters"), using: ::Kernel.raise(::ArgumentError, "missing keyword: using"), context: ::Kernel.raise(::ArgumentError, "missing keyword: context"))
        rewriters.inject(source) do |src, rewriter|
          buffer = Parser::Source::Buffer.new("<dynamic>")
          buffer.source = src

          rewriter.new(context).rewrite(buffer, parse(src))
        end.then do |new_source|
          next source unless context.dirty?

          new_source
        end
      end

      attr_writer :watch_dirs
    end

    self.rewriters = []
    self.watch_dirs = %w[app lib spec test].map { |path| File.join(Dir.pwd, path) }
    self.mode = ENV.fetch("RUBY_NEXT_TRANSPILE_MODE", "rewrite").to_sym

    require "ruby-next/language/rewriters/base"

    require "ruby-next/language/rewriters/2.1/numeric_literals"
    rewriters << Rewriters::NumericLiterals

    require "ruby-next/language/rewriters/2.1/required_kwargs"
    rewriters << Rewriters::RequiredKwargs

    require "ruby-next/language/rewriters/2.3/squiggly_heredoc"
    rewriters << Rewriters::SquigglyHeredoc

    require "ruby-next/language/rewriters/2.3/safe_navigation"
    rewriters << Rewriters::SafeNavigation

    require "ruby-next/language/rewriters/2.5/rescue_within_block"
    rewriters << Rewriters::RescueWithinBlock

    require "ruby-next/language/rewriters/2.7/args_forward"
    rewriters << Rewriters::ArgsForward

    require "ruby-next/language/rewriters/2.7/numbered_params"
    rewriters << Rewriters::NumberedParams

    require "ruby-next/language/rewriters/2.7/pattern_matching"
    rewriters << Rewriters::PatternMatching

    # Must be added after general args forward rewriter to become
    # no-op in Ruby <2.7
    require "ruby-next/language/rewriters/3.0/args_forward_leading"
    rewriters << Rewriters::ArgsForwardLeading

    # Must be added after general pattern matching rewriter to become
    # no-op in Ruby <2.7
    require "ruby-next/language/rewriters/3.0/find_pattern"
    rewriters << Rewriters::FindPattern

    require "ruby-next/language/rewriters/3.0/in_pattern"
    rewriters << Rewriters::InPattern

    require "ruby-next/language/rewriters/3.0/endless_method"
    RubyNext::Language.rewriters << RubyNext::Language::Rewriters::EndlessMethod

    require "ruby-next/language/rewriters/3.1/oneline_pattern_parensless"
    rewriters << Rewriters::OnelinePatternParensless

    require "ruby-next/language/rewriters/3.1/pin_vars_pattern"
    rewriters << Rewriters::PinVarsPattern

    require "ruby-next/language/rewriters/3.1/anonymous_block"
    rewriters << Rewriters::AnonymousBlock

    require "ruby-next/language/rewriters/3.1/refinement_import_methods"
    rewriters << Rewriters::RefinementImportMethods

    require "ruby-next/language/rewriters/3.1/endless_method_command"
    rewriters << Rewriters::EndlessMethodCommand

    require "ruby-next/language/rewriters/3.1/shorthand_hash"
    rewriters << RubyNext::Language::Rewriters::ShorthandHash

    # Put endless range in the end, 'cause Parser fails to parse it in
    # pattern matching
    require "ruby-next/language/rewriters/2.6/endless_range"
    rewriters << Rewriters::EndlessRange

    if ENV["RUBY_NEXT_EDGE"] == "1"
      require "ruby-next/language/rewriters/edge"
    end

    if ENV["RUBY_NEXT_PROPOSED"] == "1"
      require "ruby-next/language/rewriters/proposed"
    end
  end
end
