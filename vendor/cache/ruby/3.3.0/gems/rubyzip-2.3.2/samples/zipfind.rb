#!/usr/bin/env ruby

$VERBOSE = true

$LOAD_PATH << '../lib'

require 'zip'
require 'find'

module Zip
  module ZipFind
    def self.find(path, zip_file_pattern = /\.zip$/i)
      Find.find(path) do |filename|
        yield(filename)
        next unless zip_file_pattern.match(filename) && File.file?(filename)

        begin
          Zip::File.foreach(filename) do |entry|
            yield(filename + File::SEPARATOR + entry.to_s)
          end
        rescue Errno::EACCES => e
          puts e
        end
      end
    end

    def self.find_file(path, filename_pattern, zip_file_pattern = /\.zip$/i)
      find(path, zip_file_pattern) do |filename|
        yield(filename) if filename_pattern.match(filename)
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  module ZipFindConsoleRunner
    PATH_ARG_INDEX = 0
    FILENAME_PATTERN_ARG_INDEX = 1
    ZIPFILE_PATTERN_ARG_INDEX = 2

    def self.run(args)
      check_args(args)
      Zip::ZipFind.find_file(args[PATH_ARG_INDEX],
                             args[FILENAME_PATTERN_ARG_INDEX],
                             args[ZIPFILE_PATTERN_ARG_INDEX]) do |filename|
        report_entry_found filename
      end
    end

    def self.check_args(args)
      return if args.size == 3

      usage
      exit
    end

    def self.usage
      puts "Usage: #{$PROGRAM_NAME} PATH ZIPFILENAME_PATTERN FILNAME_PATTERN"
    end

    def self.report_entry_found(filename)
      puts filename
    end
  end

  ZipFindConsoleRunner.run(ARGV)
end
