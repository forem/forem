# frozen_string_literal: true

require 'open3'
require 'rubygems'
require 'json'

module Solargraph
  # A workspace consists of the files in a project's directory and the
  # project's configuration. It provides a Source for each file to be used
  # in an associated Library or ApiMap.
  #
  class Workspace
    autoload :Config, 'solargraph/workspace/config'

    # @return [String]
    attr_reader :directory

    # The require paths associated with the workspace.
    #
    # @return [Array<String>]
    attr_reader :require_paths

    # @return [Array<String>]
    attr_reader :gemnames
    alias source_gems gemnames

    # @param directory [String]
    # @param config [Config, nil]
    def initialize directory = '', config = nil
      @directory = directory
      @config = config
      load_sources
      @gemnames = []
      @require_paths = generate_require_paths
      require_plugins
    end

    # @return [Solargraph::Workspace::Config]
    def config
      @config ||= Solargraph::Workspace::Config.new(directory)
    end

    # Merge the source. A merge will update the existing source for the file
    # or add it to the sources if the workspace is configured to include it.
    # The source is ignored if the configuration excludes it.
    #
    # @param source [Solargraph::Source]
    # @return [Boolean] True if the source was added to the workspace
    def merge *sources
      unless directory == '*' || sources.all? { |source| source_hash.key?(source.filename) }
        # Reload the config to determine if a new source should be included
        @config = Solargraph::Workspace::Config.new(directory)
      end

      includes_any = false
      sources.each do |source|
        if directory == "*" || config.calculated.include?(source.filename)
          source_hash[source.filename] = source
          includes_any = true
        end
      end

      includes_any
    end

    # Remove a source from the workspace. The source will not be removed if
    # its file exists and the workspace is configured to include it.
    #
    # @param filename [String]
    # @return [Boolean] True if the source was removed from the workspace
    def remove filename
      return false unless source_hash.key?(filename)
      source_hash.delete filename
      true
    end

    # @return [Array<String>]
    def filenames
      source_hash.keys
    end

    # @return [Array<Solargraph::Source>]
    def sources
      source_hash.values
    end

    # @param filename [String]
    # @return [Boolean]
    def has_file? filename
      source_hash.key?(filename)
    end

    # Get a source by its filename.
    #
    # @param filename [String]
    # @return [Solargraph::Source]
    def source filename
      source_hash[filename]
    end

    # True if the path resolves to a file in the workspace's require paths.
    #
    # @param path [String]
    # @return [Boolean]
    def would_require? path
      require_paths.each do |rp|
        return true if File.exist?(File.join(rp, "#{path}.rb"))
      end
      false
    end

    # True if the workspace contains at least one gemspec file.
    #
    # @return [Boolean]
    def gemspec?
      !gemspecs.empty?
    end

    # Get an array of all gemspec files in the workspace.
    #
    # @return [Array<String>]
    def gemspecs
      return [] if directory.empty? || directory == '*'
      @gemspecs ||= Dir[File.join(directory, '**/*.gemspec')].select do |gs|
        config.allow? gs
      end
    end

    # Synchronize the workspace from the provided updater.
    #
    # @param updater [Source::Updater]
    # @return [void]
    def synchronize! updater
      source_hash[updater.filename] = source_hash[updater.filename].synchronize(updater)
    end

    private

    # @return [Hash{String => Solargraph::Source}]
    def source_hash
      @source_hash ||= {}
    end

    # @return [void]
    def load_sources
      source_hash.clear
      unless directory.empty? || directory == '*'
        size = config.calculated.length
        raise WorkspaceTooLargeError, "The workspace is too large to index (#{size} files, #{config.max_files} max)" if config.max_files > 0 and size > config.max_files
        config.calculated.each do |filename|
          begin
            source_hash[filename] = Solargraph::Source.load(filename)
          rescue Errno::ENOENT => e
            Solargraph.logger.warn("Error loading #{filename}: [#{e.class}] #{e.message}")
          end
        end
      end
    end

    # Generate require paths from gemspecs if they exist or assume the default
    # lib directory.
    #
    # @return [Array<String>]
    def generate_require_paths
      return configured_require_paths unless gemspec?
      result = []
      gemspecs.each do |file|
        base = File.dirname(file)
        # HACK: Evaluating gemspec files violates the goal of not running
        #   workspace code, but this is how Gem::Specification.load does it
        #   anyway.
        cmd = ['ruby', '-e', "require 'rubygems'; require 'json'; spec = eval(File.read('#{file}'), TOPLEVEL_BINDING, '#{file}'); return unless Gem::Specification === spec; puts({name: spec.name, paths: spec.require_paths}.to_json)"]
        o, e, s = Open3.capture3(*cmd)
        if s.success?
          begin
            hash = o && !o.empty? ? JSON.parse(o.split("\n").last) : {}
            next if hash.empty?
            @gemnames.push hash['name']
            result.concat(hash['paths'].map { |path| File.join(base, path) })
          rescue StandardError => e
            Solargraph.logger.warn "Error reading #{file}: [#{e.class}] #{e.message}"
          end
        else
          Solargraph.logger.warn "Error reading #{file}"
          Solargraph.logger.warn e
        end
      end
      result.concat(config.require_paths.map { |p| File.join(directory, p) })
      result.push File.join(directory, 'lib') if result.empty?
      result
    end

    # Get additional require paths defined in the configuration.
    #
    # @return [Array<String>]
    def configured_require_paths
      return ['lib'] if directory.empty?
      return [File.join(directory, 'lib')] if config.require_paths.empty?
      config.require_paths.map{|p| File.join(directory, p)}
    end

    def require_plugins
      config.plugins.each do |plugin|
        begin
          require plugin
        rescue LoadError
          Solargraph.logger.warn "Failed to load plugin '#{plugin}'"
        end
      end
    end
  end
end
