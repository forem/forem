# frozen_string_literal: true

require "pathname"

require "ruby-next"
require "ruby-next/utils"
require "ruby-next/language"
require "ruby-next/language/eval"

module RubyNext
  module Language
    runtime!

    # Module responsible for runtime transformations
    module Runtime
      using RubyNext

      class << self
        include Utils

        def load(path, wrap: false)
          raise "RubyNext cannot handle `load(smth, wrap: true)`" if wrap

          contents = File.read(path)
          new_contents = transform contents

          RubyNext.debug_source new_contents, path

          evaluate(new_contents, path)
          true
        end

        def transform(contents, **options)
          Language.transform(contents, rewriters: Language.current_rewriters, **options)
        end

        def feature_path(path)
          path = resolve_feature_path(path)
          return if path.nil?
          return if File.extname(path) != ".rb"
          return unless Language.transformable?(path)
          path
        end

        if defined?(JRUBY_VERSION) || defined?(TruffleRuby)
          def evaluate(code, filepath)
            new_toplevel.eval(code, filepath)
          end

          def new_toplevel
            # Create new "toplevel" binding to avoid lexical scope re-use
            # (aka "leaking refinements")
            eval "proc{binding}.call", TOPLEVEL_BINDING, __FILE__, __LINE__
          end
        else
          def evaluate(code, filepath)
            # This is workaround to solve the "leaking refinements" problem in MRI
            RubyVM::InstructionSequence.compile(code, filepath).then do |iseq|
              iseq.eval
            end
          end
        end
      end
    end
  end
end

# Patch Kernel to hijack require/require_relative/load/eval
module Kernel
  module_function

  alias_method :require_without_ruby_next, :require
  def require(path)
    realpath = RubyNext::Language::Runtime.feature_path(path)
    return require_without_ruby_next(path) unless realpath

    return false if $LOADED_FEATURES.include?(realpath)

    $LOADED_FEATURES << realpath

    RubyNext::Language::Runtime.load(realpath)

    true
  rescue => e
    $LOADED_FEATURES.delete realpath
    RubyNext.warn "RubyNext failed to require '#{path}': #{e.message}"
    require_without_ruby_next(path)
  end

  alias_method :require_relative_without_ruby_next, :require_relative
  def require_relative(path)
    loc = caller_locations(1..1).first
    from = loc.absolute_path || loc.path || File.join(Dir.pwd, "main")
    realpath = File.absolute_path(
      File.join(
        File.dirname(File.absolute_path(from)),
        path
      )
    )
    require(realpath)
  rescue => e
    RubyNext.warn "RubyNext failed to require relative '#{path}' from #{from}: #{e.message}"
    require_relative_without_ruby_next(path)
  end

  alias_method :load_without_ruby_next, :load
  def load(path, wrap = false)
    realpath = RubyNext::Language::Runtime.feature_path(path)

    return load_without_ruby_next(path, wrap) unless realpath

    RubyNext::Language::Runtime.load(realpath, wrap: wrap)
  rescue => e
    RubyNext.warn "RubyNext failed to load '#{path}': #{e.message}"
    load_without_ruby_next(path)
  end
end
