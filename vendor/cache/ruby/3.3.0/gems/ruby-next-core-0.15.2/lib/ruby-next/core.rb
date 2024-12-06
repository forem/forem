# frozen_string_literal: true

require "set"

require "ruby-next/config"
require "ruby-next/utils"

module RubyNext
  module Core
    # Patch contains the extension implementation
    # and meta information (e.g., Ruby version).
    class Patch
      attr_reader :refineables, :name, :mod, :method_name, :version, :body, :singleton, :core_ext, :supported, :native, :location

      # Create a new patch for module/class (mod)
      # with the specified uniq name
      #
      # `core_ext` defines the strategy for core extensions:
      #    - :patch — extend class directly
      #    - :prepend — extend class by prepending a module (e.g., when needs `super`)
      def initialize(mod = nil, method:, version:, name: nil, supported: nil, native: nil, location: nil, refineable: mod, core_ext: :patch, singleton: nil)
        @mod = mod
        @method_name = method
        @version = version
        if method_name && mod
          @supported = supported.nil? ? mod.method_defined?(method_name) : supported
          # define whether running Ruby has a native implementation for this method
          # for that, we check the source_location (which is nil for C defined methods)
          @native = native.nil? ? (supported? && native_location?(mod.instance_method(method_name).source_location)) : native
        end
        @singleton = singleton
        @refineables = Array(refineable)
        @body = yield
        @core_ext = core_ext
        @location = location || build_location(caller_locations(1, 5))
        @name = name || build_module_name
      end

      def prepend?
        core_ext == :prepend
      end

      def core_ext?
        !mod.nil?
      end

      alias supported? supported
      alias native? native
      alias singleton? singleton

      def to_module
        Module.new.tap do |ext|
          ext.module_eval(body, *location)

          RubyNext::Core.const_set(name, ext)
        end
      end

      private

      def build_module_name
        mod_name = singleton? ? singleton.name : mod.name
        camelized_method_name = method_name.to_s.split("_").map(&:capitalize).join

        "#{mod_name}#{camelized_method_name}".gsub(/\W/, "")
      end

      def build_location(trace_locations)
        # The caller_locations behaviour depends on implementaion,
        # e.g. in JRuby https://github.com/jruby/jruby/issues/6055
        while trace_locations.first.label != "patch"
          trace_locations.shift
        end

        trace_location = trace_locations[1]

        [trace_location.absolute_path, trace_location.lineno + 2]
      end

      def native_location?(location)
        location.nil? || location.first.match?(/(<internal:|resource:\/truffleruby\/core)/)
      end
    end

    # Registry for patches
    class Patches
      attr_reader :extensions, :refined

      def initialize
        @names = Set.new
        @extensions = Hash.new { |h, k| h[k] = [] }
        @refined = Hash.new { |h, k| h[k] = [] }
      end

      # Register new patch
      def <<(patch)
        raise ArgumentError, "Patch already registered: #{patch.name}" if @names.include?(patch.name)
        @names << patch.name
        @extensions[patch.mod] << patch if patch.core_ext?
        patch.refineables.each { |r| @refined[r] << patch } unless patch.native?
      end
    end

    class << self
      STRATEGIES = %i[refine core_ext backports].freeze

      attr_reader :strategy

      def strategy=(val)
        raise ArgumentError, "Unknown strategy: #{val}. Available: #{STRATEGIES.join(",")}" unless STRATEGIES.include?(val)
        @strategy = val
      end

      def refine?
        strategy == :refine
      end

      def core_ext?
        strategy == :core_ext || strategy == :backports
      end

      def backports?
        strategy == :backports
      end

      def patch(...)
        patches << Patch.new(...)
      end

      # Inject `using RubyNext` at the top of the source code
      def inject!(contents)
        if contents.frozen?
          contents = contents.sub(/^(\s*[^#\s].*)/, 'using RubyNext;\1')
        else
          contents.sub!(/^(\s*[^#\s].*)/, 'using RubyNext;\1')
        end
        contents
      end

      def patches
        @patches ||= Patches.new
      end
    end

    # Use refinements by default
    self.strategy = ENV.fetch("RUBY_NEXT_CORE_STRATEGY", "refine").to_sym
  end
end

require "backports/2.5" if RubyNext::Core.backports?

require "ruby-next/core/kernel/then"

require "ruby-next/core/proc/compose"

require "ruby-next/core/enumerable/tally"
require "ruby-next/core/enumerable/filter"
require "ruby-next/core/enumerable/filter_map"

require "ruby-next/core/enumerator/produce"

require "ruby-next/core/array/difference_union_intersection"

require "ruby-next/core/hash/merge"

require "ruby-next/core/string/split"

require "ruby-next/core/symbol/start_with"
require "ruby-next/core/symbol/end_with"

require "ruby-next/core/unboundmethod/bind_call"

require "ruby-next/core/time/floor"
require "ruby-next/core/time/ceil"

require "ruby-next/core/refinement/import"

# Core extensions required for pattern matching
# Required for pattern matching with refinements
unless defined?(NoMatchingPatternError)
  class NoMatchingPatternError < StandardError
  end
end

require "ruby-next/core/constants/no_matching_pattern_error"
require "ruby-next/core/constants/frozen_error"
require "ruby-next/core/array/deconstruct"
require "ruby-next/core/hash/deconstruct_keys"
require "ruby-next/core/struct/deconstruct"
require "ruby-next/core/struct/deconstruct_keys"

require "ruby-next/core/hash/except"

require "ruby-next/core/array/intersect"

require "ruby-next/core/matchdata/match"
require "ruby-next/core/enumerable/compact"
require "ruby-next/core/integer/try_convert"

# Generate refinements
RubyNext.module_eval do
  RubyNext::Core.patches.refined.each do |mod, patches|
    # Only refine modules when supported
    next unless mod.is_a?(Class) || RubyNext::Utils.refine_modules?

    refine mod do
      patches.each do |patch|
        module_eval(patch.body, *patch.location)
      end
    end
  end
end
