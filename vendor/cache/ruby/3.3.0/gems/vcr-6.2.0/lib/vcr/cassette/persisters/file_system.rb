require 'fileutils'

module VCR
  class Cassette
    class Persisters
      # The only built-in cassette persister. Persists cassettes to the file system.
      module FileSystem
        extend self

        # @private
        attr_reader :storage_location

        # @private
        def storage_location=(dir)
          FileUtils.mkdir_p(dir) if dir
          @storage_location = dir ? absolute_path_for(dir) : nil
        end

        # Gets the cassette for the given storage key (file name).
        #
        # @param [String] file_name the file name
        # @return [String] the cassette content
        def [](file_name)
          path = absolute_path_to_file(file_name)
          return nil unless File.exist?(path)
          File.binread(path)
        end

        # Sets the cassette for the given storage key (file name).
        #
        # @param [String] file_name the file name
        # @param [String] content the content to store
        def []=(file_name, content)
          path = absolute_path_to_file(file_name)
          directory = File.dirname(path)
          FileUtils.mkdir_p(directory) unless File.exist?(directory)
          File.binwrite(path, content)
        end

        # @private
        def absolute_path_to_file(file_name)
          return nil unless storage_location
          File.join(storage_location, sanitized_file_name_from(file_name))
        end

      private
        def absolute_path_for(path)
          Dir.chdir(path) { Dir.pwd }
        end

        def sanitized_file_name_from(file_name)
          parts = file_name.to_s.split('.')

          if parts.size > 1 && !parts.last.include?(File::SEPARATOR)
            file_extension = '.' + parts.pop
          end

          file_name = parts.join('.').gsub(/[^[:word:]\-\/]+/, '_') + file_extension.to_s
          file_name.downcase! if downcase_cassette_names?
          file_name
        end

        def downcase_cassette_names?
          !!VCR.configuration
            .default_cassette_options
            .dig(:persister_options, :downcase_cassette_names)
        end
      end
    end
  end
end
