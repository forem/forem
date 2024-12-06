module Solargraph
  module Rails
    class FilesLoader
      def initialize(file_names)
        @file_names = file_names
      end

      def each(&blk)
        @file_names.each do |file_name|
          Solargraph::Logging.logger.info "loading from #{file_name}"
          blk.call(file_name, File.read(file_name))
        end
      end
    end
  end
end
