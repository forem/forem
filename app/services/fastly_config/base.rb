module FastlyConfig
  class Base
    attr_reader :fastly, :active_version, :updated_files

    def initialize(fastly, active_version)
      @fastly = fastly
      @active_version = active_version
      @updated_files = get_updated_files
    end

    def update_needed?
      updated_files.present?
    end

    def update(new_version)
      updated_files.each { |filename| update_config(new_version, filename) }
    end

    private

    def get_updated_files(files: self.class::FASTLY_FILES)
      updated_files = []
      Dir.glob(files).each { |filename| updated_files << filename if file_updated?(filename) }
      updated_files
    end

    def file_updated?
      raise FastlyConfig::Errors::Error, "Fastly configs must implement their own file_updated? method"
    end

    def upsert_config
      raise FastlyConfig::Errors::Error, "Fastly configs must implement their own update_config method"
    end
  end
end
