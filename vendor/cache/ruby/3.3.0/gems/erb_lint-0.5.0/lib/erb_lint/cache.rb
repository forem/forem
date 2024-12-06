# frozen_string_literal: true

module ERBLint
  class Cache
    CACHE_DIRECTORY = ".erb-lint-cache"

    def initialize(config, cache_dir = nil)
      @config = config
      @cache_dir = cache_dir || CACHE_DIRECTORY
      @hits = []
      @new_results = []
      puts "Cache mode is on"
    end

    def get(filename, file_content)
      file_checksum = checksum(filename, file_content)
      begin
        cache_file_contents_as_offenses = JSON.parse(
          File.read(File.join(@cache_dir, file_checksum))
        ).map do |offense_hash|
          ERBLint::CachedOffense.new(offense_hash)
        end
      rescue Errno::ENOENT
        return false
      end
      @hits.push(file_checksum)
      cache_file_contents_as_offenses
    end

    def set(filename, file_content, offenses_as_json)
      file_checksum = checksum(filename, file_content)
      @new_results.push(file_checksum)

      FileUtils.mkdir_p(@cache_dir)

      File.open(File.join(@cache_dir, file_checksum), "wb") do |f|
        f.write(offenses_as_json)
      end
    end

    def close
      prune_cache
    end

    def prune_cache
      if hits.empty?
        puts "Cache being created for the first time, skipping prune"
        return
      end

      cache_files = Dir.new(@cache_dir).children
      cache_files.each do |cache_file|
        next if hits.include?(cache_file) || new_results.include?(cache_file)

        File.delete(File.join(@cache_dir, cache_file))
      end
    end

    def cache_dir_exists?
      File.directory?(@cache_dir)
    end

    def clear
      return unless cache_dir_exists?

      puts "Clearing cache by deleting cache directory"
      FileUtils.rm_r(@cache_dir)
    end

    private

    attr_reader :config, :hits, :new_results

    def checksum(filename, file_content)
      digester = Digest::SHA1.new
      mode = File.stat(filename).mode

      digester.update(
        "#{mode}#{config.to_hash}#{ERBLint::VERSION}#{file_content}"
      )
      digester.hexdigest
    rescue Errno::ENOENT
      # Spurious files that come and go should not cause a crash, at least not
      # here.
      "_"
    end
  end
end
