require 'fileutils'

module Solargraph
  module Cache
    class << self
      # The base directory where cached documentation is installed.
      #
      # @return [String]
      def base_dir
        # The directory is not stored in a variable so it can be overridden
        # in specs.
        ENV['SOLARGRAPH_CACHE'] ||
          ENV['XDG_CACHE_HOME'] ? File.join(ENV['XDG_CACHE_HOME'], 'solargraph') :
          File.join(Dir.home, '.cache', 'solargraph')
      end

      # The working directory for the current Ruby and Solargraph versions.
      #
      # @return [String]
      def work_dir
        # The directory is not stored in a variable so it can be overridden
        # in specs.
        File.join(base_dir, "ruby-#{RUBY_VERSION}", "rbs-#{RBS::VERSION}", "solargraph-#{Solargraph::VERSION}")
      end

      # @return [Array<Solargraph::Pin::Base>, nil]
      def load *path
        file = File.join(work_dir, *path)
        return nil unless File.file?(file)
        Marshal.load(File.read(file, mode: 'rb'))
      rescue StandardError => e
        Solargraph.logger.warn "Failed to load cached file #{file}: [#{e.class}] #{e.message}"
        FileUtils.rm_f file
        nil
      end

      # @return [Boolean]
      def save *path, pins
        return false if pins.empty?
        file = File.join(work_dir, *path)
        base = File.dirname(file)
        FileUtils.mkdir_p base unless File.directory?(base)
        ser = Marshal.dump(pins)
        File.write file, ser, mode: 'wb'
        true
      end

      def clear
        FileUtils.rm_rf base_dir, secure: true
      end
    end
  end
end
