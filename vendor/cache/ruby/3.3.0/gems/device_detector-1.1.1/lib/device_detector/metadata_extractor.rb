# frozen_string_literal: true

class DeviceDetector
  class MetadataExtractor < Struct.new(:user_agent, :regex_meta)
    def call
      regex_meta.any? ? extract_metadata : nil
    end

    private

    def metadata_string
      message = "#{name} (a child of MetadataExtractor) must implement the '#{__method__}' method."
      raise NotImplementedError, message
    end

    def extract_metadata
      user_agent.match(regex) do |match_data|
        metadata_string.gsub(/\$(\d)/) do
          match_data[Regexp.last_match(1).to_i].to_s
        end.strip
      end
    end

    def regex
      @regex ||= regex_meta[:regex]
    end
  end
end
