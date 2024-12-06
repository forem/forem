# frozen_string_literal: true

class DeviceDetector
  class VersionExtractor < MetadataExtractor
    MAJOR_VERSION_2 = Gem::Version.new('2.0')
    MAJOR_VERSION_3 = Gem::Version.new('3.0')
    MAJOR_VERSION_4 = Gem::Version.new('4.0')
    MAJOR_VERSION_8 = Gem::Version.new('8.0')

    def call
      simple_version = super&.chomp('.')

      return simple_version unless simple_version&.empty?

      os_version_by_regexes
    end

    private

    def os_version_by_regexes
      version_matches = regex_meta[:versions]
      return '' unless version_matches

      version_matches.detect do |matcher|
        user_agent.match(matcher[:regex]) do |match_data|
          return matcher[:version].gsub(/\$(\d)/) do
            match_data[Regexp.last_match(1).to_i].to_s
          end.strip
        end
      end

      ''
    end

    def metadata_string
      String(regex_meta[:version])
    end
  end
end
