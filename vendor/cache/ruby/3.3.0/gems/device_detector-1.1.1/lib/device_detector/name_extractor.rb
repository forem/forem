# frozen_string_literal: true

class DeviceDetector
  class NameExtractor < MetadataExtractor
    def call
      if /\$[0-9]/ =~ metadata_string
        extract_metadata
      else
        metadata_string
      end
    end

    private

    def metadata_string
      regex_meta[:name]
    end
  end
end
