# frozen_string_literal: true

module Sources
  module Local
    # Auxiliary Subdivision class to support loading the local subdivision data to be updated with Unicode CLDR data
    class Subdivision
      attr_reader :code

      def initialize(code)
        @code = code
      end

      def load
        if File.exist?(file_path)
          YAML.load_file(file_path) || {}
        else
          {}
        end
      end

      def save(data)
        File.write(file_path, data.to_yaml)
      rescue StandardError
        puts "failed to read #{file}: #{$ERROR_INFO}"
      end

      def file_path
        "lib/countries/data/subdivisions/#{code}.yaml"
      end

      def self.load(code)
        new(code).load
      end
    end
  end
end
