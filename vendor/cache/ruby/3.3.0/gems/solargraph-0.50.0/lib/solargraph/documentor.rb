# frozen_string_literal: true

require 'bundler'
require 'json'
require 'open3'
require 'shellwords'
require 'yard'
require 'fileutils'

module Solargraph
  class Documentor
    RDOC_GEMS = %w[
      actioncable actionmailbox actionmailer actionpack actiontext actionview
      activejob activemodel activerecord activestorage activesupport railties
    ]

    def initialize directory, rebuild: false, out: File.new(File::NULL, 'w')
      @directory = directory
      @rebuild = rebuild
      @out = out
    end

    # @return [Boolean] True if all specs were found and documented.
    def document
      failures = 0
      Documentor.specs_from_bundle(@directory).each_pair do |name, version|
        yd = YARD::Registry.yardoc_file_for_gem(name, "= #{version}")
        if !yd || @rebuild
          FileUtils.safe_unlink File.join(YardMap::CoreDocs.cache_dir, 'gems', "#{name}-#{version}.ser")
          @out.puts "Documenting #{name} #{version}"
          `yard gems #{name} #{version} #{@rebuild ? '--rebuild' : ''}`
          yd = YARD::Registry.yardoc_file_for_gem(name, "= #{version}")
          # HACK: Ignore errors documenting bundler
          if !yd && name != 'bundler'
            @out.puts "#{name} #{version} YARD documentation failed"
            failures += 1
          end
        end
        if yd && RDOC_GEMS.include?(name)
          cache = File.join(Solargraph::YardMap::CoreDocs.cache_dir, 'gems', "#{name}-#{version}", 'yardoc')
          if !File.exist?(cache) || @rebuild
            @out.puts "Caching custom documentation for #{name} #{version}"
            spec = Gem::Specification.find_by_name(name, "= #{version}")
            Solargraph::YardMap::RdocToYard.run(spec)
          end
        end
      end
      if failures > 0
        @out.puts "#{failures} gem#{failures == 1 ? '' : 's'} could not be documented. You might need to run `bundle install`."
      end
      failures == 0
    rescue Solargraph::BundleNotFoundError => e
      @out.puts "[#{e.class}] #{e.message}"
      @out.puts "No bundled gems are available in #{@directory}"
      false
    end

    # @param directory [String]
    # @return [Hash]
    def self.specs_from_bundle directory
      Solargraph.with_clean_env do
        cmd = [
          'ruby', '-e',
          "require 'bundler'; require 'json'; Dir.chdir('#{directory}') { puts Bundler.definition.specs_for([:default]).map { |spec| [spec.name, spec.version] }.to_h.to_json }"
        ]
        o, e, s = Open3.capture3(*cmd)
        if s.success?
          o && !o.empty? ? JSON.parse(o.split("\n").last) : {}
        else
          Solargraph.logger.warn e
          raise BundleNotFoundError, "Failed to load gems from bundle at #{directory}"
        end
      end
    end
  end
end
