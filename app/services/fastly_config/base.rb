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
      updated_files.each { |filename| upsert_config(new_version, filename) }
    end

    private

    def get_updated_files(files: self.class::FASTLY_FILES)
      Dir.glob(files).filter_map { |filename| filename if file_updated?(filename) }
    end

    def file_updated?
      raise SubclassResponsibility, "Fastly configs must implement their own file_updated? method"
    end

    def upsert_config
      raise SubclassResponsibility, "Fastly configs must implement their own upsert_config method"
    end
  end
end
