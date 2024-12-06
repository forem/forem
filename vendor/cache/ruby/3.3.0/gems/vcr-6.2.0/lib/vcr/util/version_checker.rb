module VCR
  # @private
  class VersionChecker
    def initialize(library_name, library_version, min_version)
      @library_name    = library_name
      @library_version = library_version
      @min_version     = min_version

      @major,     @minor,     @patch     = parse_version(library_version)
      @min_major, @min_minor, @min_patch = parse_version(min_version)
    end

    def check_version!
      raise_too_low_error if too_low?
    end

  private

    def too_low?
      compare_version == :too_low
    end

    def raise_too_low_error
      raise Errors::LibraryVersionTooLowError,
        "You are using #{@library_name} #{@library_version}. " +
        "VCR requires version #{version_requirement}."
    end

    def compare_version
      case
        when @major < @min_major then :too_low
        when @major > @min_major then :ok
        when @minor < @min_minor then :too_low
        when @minor > @min_minor then :ok
        when @patch < @min_patch then :too_low
      end
    end

    def version_requirement
      ">= #{@min_version}"
    end

    def parse_version(version)
      version.split('.').map { |v| v.to_i }
    end
  end
end

