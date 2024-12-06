# frozen_string_literal: true

module KnapsackPro
  module Config
    class TempFiles
      # relative to the directory where you run knapsack_pro gem (user's project)
      TEMP_DIRECTORY_PATH = '.knapsack_pro'

      def self.ensure_temp_directory_exists!
        unless File.exist?(gitignore_file_path)
          create_temp_directory!
          create_gitignore_file!
        end
      end

      private

      def self.create_temp_directory!
        FileUtils.mkdir_p(TEMP_DIRECTORY_PATH)
      end

      def self.gitignore_file_path
        File.join(TEMP_DIRECTORY_PATH, '.gitignore')
      end

      def self.gitignore_file_content
        <<~GITIGNORE
        # This directory is used by knapsack_pro gem for storing temporary files during tests runtime.
        # Ignore all files, and do not commit this directory into your repository.
        # Learn more at https://knapsackpro.com
        *
        GITIGNORE
      end

      def self.create_gitignore_file!
        File.open(gitignore_file_path, 'w+') do |f|
          f.write(gitignore_file_content)
        end
      end
    end
  end
end
