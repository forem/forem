# frozen_string_literal: true

require 'rbs'
require 'set'

module Solargraph
  class RbsMap
    autoload :Conversions, 'solargraph/rbs_map/conversions'
    autoload :CoreMap,     'solargraph/rbs_map/core_map'
    autoload :CoreFills,   'solargraph/rbs_map/core_fills'
    autoload :CoreSigns,   'solargraph/rbs_map/core_signs'
    autoload :StdlibMap,   'solargraph/rbs_map/stdlib_map'

    include Conversions

    # @type [Hash{String => RbsMap}]
    @@rbs_maps_hash = {}

    attr_reader :library

    # @param library [String]
    def initialize library
      @library = library
      loader = RBS::EnvironmentLoader.new(core_root: nil, repository: repository)
      add_library loader, library
      return unless resolved?
      environment = RBS::Environment.from_loader(loader).resolve_type_names
      environment.declarations.each { |decl| convert_decl_to_pin(decl, Solargraph::Pin::ROOT_PIN) }
    end

    def path_pin path
      pins.find { |p| p.path == path }
    end

    def path_pins path
      pins.select { |p| p.path == path }
    end

    def resolved?
      @resolved
    end

    # @param library [String]
    # @return [RbsMap]
    def self.load library
      @@rbs_maps_hash[library] ||= RbsMap.new(library)
    end

    def repository
      @repository ||= RBS::Repository.new(no_stdlib: true)
    end

    private

    # @param loader [RBS::EnvironmentLoader]
    # @param library [String]
    # @return [Boolean] true if adding the library succeeded
    def add_library loader, library
      @resolved = if loader.has_library?(library: library, version: nil)
        loader.add library: library
        Solargraph.logger.info "#{short_name} successfully loaded library #{library}"
        true
      else
        Solargraph.logger.info "#{short_name} failed to load library #{library}"
        false
      end
    end

    def short_name
      self.class.name.split('::').last
    end
  end
end
