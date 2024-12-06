# frozen_string_literal: true

require 'yard'
require 'yard-solargraph'
require 'rubygems/package'
require 'set'

module Solargraph
  # The YardMap provides access to YARD documentation for the Ruby core, the
  # stdlib, and gems.
  #
  class YardMap
    class NoYardocError < StandardError; end

    autoload :Cache,       'solargraph/yard_map/cache'
    autoload :Mapper,      'solargraph/yard_map/mapper'
    autoload :RdocToYard,  'solargraph/yard_map/rdoc_to_yard'
    autoload :Helpers,     'solargraph/yard_map/helpers'
    autoload :ToMethod,    'solargraph/yard_map/to_method'

    include ApiMap::BundlerMethods

    # @return [Boolean]
    attr_writer :with_dependencies

    # @param required [Array<String>, Set<String>]
    # @param directory [String]
    # @param source_gems [Array<String>, Set<String>]
    # @param with_dependencies [Boolean]
    def initialize(required: [], directory: '', source_gems: [], with_dependencies: true)
      @with_dependencies = with_dependencies
      change required.to_set, directory, source_gems.to_set
    end

    # @return [Array<Solargraph::Pin::Base>]
    def pins
      @pins ||= []
    end

    def with_dependencies?
      @with_dependencies ||= true unless @with_dependencies == false
      @with_dependencies
    end

    # @param new_requires [Set<String>] Required paths to use for loading gems
    # @param new_directory [String] The workspace directory
    # @param new_source_gems [Set<String>] Gems under local development (i.e., part of the workspace)
    # @return [Boolean]
    def change new_requires, new_directory, new_source_gems
      return false if new_requires == base_required && new_directory == @directory && new_source_gems == @source_gems
      @gem_paths = {}
      base_required.replace new_requires
      required.replace new_requires
      # HACK: Hardcoded YAML handling
      required.add 'psych' if new_requires.include?('yaml')
      @source_gems = new_source_gems
      @directory = new_directory
      process_requires
      @rebindable_method_names = nil
      @pin_class_hash = nil
      @pin_select_cache = {}
      pins.each { |p| p.source = :yard }
      true
    end

    # @return [Set<String>]
    def rebindable_method_names
      @rebindable_method_names ||= pins_by_class(Pin::Method)
        .select { |pin| pin.comments && pin.comments.include?('@yieldself') }
        .map(&:name)
        .concat(['instance_eval', 'instance_exec', 'class_eval', 'class_exec', 'module_eval', 'module_exec', 'define_method'])
        .to_set
    end

    # @return [Array<String>]
    def yardocs
      @yardocs ||= []
    end

    # @return [Set<String>]
    def required
      @required ||= Set.new
    end

    # @return [Array<String>]
    def unresolved_requires
      @unresolved_requires ||= []
    end

    # @return [Array<String>]
    def missing_docs
      @missing_docs ||= []
    end

    # @param y [String]
    # @return [YARD::Registry]
    def load_yardoc y
      if y.is_a?(Array)
        YARD::Registry.load y, true
      else
        YARD::Registry.load! y
      end
    rescue StandardError => e
      Solargraph::Logging.logger.warn "Error loading yardoc '#{y}' #{e.class} #{e.message}"
      yardocs.delete y
      nil
    end

    # @param path [String]
    # @return [Pin::Base]
    def path_pin path
      pins.select { |p| p.path == path }.first
    end

    # Get the location of a file referenced by a require path.
    #
    # @param path [String]
    # @return [Location]
    def require_reference path
      # @type [Gem::Specification]
      spec = spec_for_require(path)
      spec.full_require_paths.each do |rp|
        file = File.join(rp, "#{path}.rb")
        next unless File.file?(file)
        return Solargraph::Location.new(file, Solargraph::Range.from_to(0, 0, 0, 0))
      end
      nil
    rescue Gem::LoadError
      nil
    end

    def base_required
      @base_required ||= Set.new
    end

    def directory
      @directory ||= ''
    end

    private

    # @return [YardMap::Cache]
    def cache
      @cache ||= YardMap::Cache.new
    end

    # @return [Hash]
    def pin_class_hash
      @pin_class_hash ||= pins.to_set.classify(&:class).transform_values(&:to_a)
    end

    # @return [Array<Pin::Base>]
    def pins_by_class klass
      @pin_select_cache[klass] ||= pin_class_hash.select { |key, _| key <= klass }.values.flatten
    end

    # @param ns [YARD::CodeObjects::NamespaceObject]
    # @return [Array<YARD::CodeObjects::Base>]
    def recurse_namespace_object ns
      result = []
      ns.children.each do |c|
        result.push c
        result.concat recurse_namespace_object(c) if c.respond_to?(:children)
      end
      result
    end

    # @return [void]
    def process_requires
      @gemset = process_gemsets
      required.merge @gemset.keys if required.include?('bundler/require')
      pins.clear
      unresolved_requires.clear
      missing_docs.clear
      environ = Convention.for_global(self)
      done = []
      already_errored = []
      (required + environ.requires).each do |r|
        next if r.nil? || r.empty? || done.include?(r)
        done.push r
        cached = cache.get_path_pins(r)
        unless cached.nil?
          pins.concat cached
          next
        end
        result = pins_for_require r, already_errored
        result.delete_if(&:nil?)
        unless result.empty?
          cache.set_path_pins r, result
          pins.concat result
        end
      end
      if required.include?('yaml') && required.include?('psych')
        # HACK: Hardcoded YAML handling
        # @todo Why can't this be handled with an override or a virtual pin?
        pin = path_pin('YAML')
        pin.instance_variable_set(:@return_type, ComplexType.parse('Module<Psych>')) unless pin.nil?
      end
      pins.concat environ.pins
    end

    def process_error(req, result, already_errored, yd = 1)
      base = req.split('/').first
      return if already_errored.include?(base)
      already_errored.push base
      if yd.nil?
        missing_docs.push req
      else
        unresolved_requires.push req
      end
    end

    def process_gemsets
      return {} if directory.empty? || !File.file?(File.join(directory, 'Gemfile'))
      require_from_bundle(directory)
    end

    # @param r [String]
    def pins_for_require r, already_errored
      result = []
      begin
        name = r.split('/').first.to_s
        return [] if name.empty? || @source_gems.include?(name) || @gem_paths.key?(name)
        spec = spec_for_require(name)
        @gem_paths[name] = spec.full_gem_path

        yd = yardoc_file_for_spec(spec)
        # YARD detects gems for certain libraries that do not have a yardoc
        # but exist in the stdlib. `fileutils` is an example. Treat those
        # cases as errors and check the stdlib yardoc.
        if yd.nil?
          process_error(r, result, already_errored, nil)
          return []
        end
        unless yardocs.include?(yd)
          yardocs.unshift yd
          result.concat process_yardoc yd, spec
          if with_dependencies?
            (spec.dependencies - spec.development_dependencies).each do |dep|
              result.concat pins_for_require dep.name, already_errored
            end
          end
        end
      rescue Gem::LoadError, NoYardocError
        process_error(r, result, already_errored)
      end
      return result
    end

    # @param y [String, nil]
    # @param spec [Gem::Specification, nil]
    # @return [Array<Pin::Base>]
    def process_yardoc y, spec = nil
      return [] if y.nil?
      if spec
        cache = Solargraph::Cache.load('gems', "#{spec.name}-#{spec.version}.ser")
        return cache if cache
      end
      size = Dir.glob(File.join(y, '**', '*'))
        .map{ |f| File.size(f) }
        .inject(:+)
      if !size.nil? && size > 20_000_000
        Solargraph::Logging.logger.warn "Yardoc at #{y} is too large to process (#{size} bytes)"
        return []
      end
      Solargraph.logger.info "Loading #{spec.name} #{spec.version} from #{y}"
      load_yardoc y
      result = Mapper.new(YARD::Registry.all, spec).map
      raise NoYardocError, "Yardoc at #{y} is empty" if result.empty?
      if spec
        Solargraph::Cache.save 'gems', "#{spec.name}-#{spec.version}.ser", result
      end
      result
    end

    # @param spec [Gem::Specification]
    # @return [String]
    def yardoc_file_for_spec spec
      YARD::Registry.yardoc_file_for_gem(spec.name, "= #{spec.version}")
    end

    # @param path [String]
    # @return [Gem::Specification]
    def spec_for_require path
      name = path.split('/').first.to_s
      spec = Gem::Specification.find_by_name(name, @gemset[name])

      # Avoid loading the spec again if it's going to be skipped anyway
      return spec if @source_gems.include?(spec.name)
      # Avoid loading the spec again if it's already the correct version
      if @gemset[spec.name] && @gemset[spec.name] != spec.version
        begin
          return Gem::Specification.find_by_name(spec.name, "= #{@gemset[spec.name]}")
        rescue Gem::LoadError
          Solargraph.logger.warn "Unable to load #{spec.name} #{@gemset[spec.name]} specified by workspace, using #{spec.version} instead"
        end
      end
      spec
    end
  end
end
